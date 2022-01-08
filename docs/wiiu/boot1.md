# Initialization
```cpp
// Clear all memory from the end of boot1
// up to the middle of boot0 (hides main functions)
memset_range(0x0D40DF40, 0x0D4125F0, 0, 0x04);

u32 stack_size = *(u32 *)0x0D40DA80;

// Setup boot1's stack pointer
SP = 0x0D40EDB0 + stack_size

// Change into THUMB mode and call main
sub_D40C82C(0x0D400200);

// Deadlock
loc_D400278();
```

# Main
## Start (disables boot0 mapping and configures IOPI, IOMEM, EXI)
```cpp
// Copy the PRSH IV from memory
memcpy(prsh_iv_buf, 0x0D40CC11, 0x10);

// Get timer value
u32 time_boot1_start = *(u32 *)HW_TIMER;

// Clear NDEV_LED state
*(u32 *)(0x0D40E258) = 0;

u32 spare1_val = *(u32 *)HW_SPARE1;

// Disable boot0 mapping
*(u32 *)HW_SPARE1 = spare1_val | 0x1000;

// Assert RSTB_IOPI and RSTB_IOMEM
u32 resets_val = *(u32 *)HW_RSTB;
resets_val &= 0xFFF7FFFF;
resets_val |= 0x80000;
resets_val &= 0xFFFBFFFF;
resets_val |= 0x40000;
*(u32 *)HW_RSTB= resets_val;

// Enable EXI
u32 aip_prot_val = *(u32 *)HW_AIP_PROT;
aip_prot_val &= ~(0x01);
aip_prot_val |= 0x01;
*(u32 *)HW_AIP_PROT = aip_prot_val;
```

## check_hw (setups the fan's speed and power, initializes I2C for SMC and validates the hardware version)
```cpp
// Send NDEV_LED marker
send_ndev_led(0x30);

// Set FanSpeed state
sub_D405570(0x01);

// Set FanPower state
sub_D4055BC(0x01);

u32 i2c_clock = 0x0A;
u32 i2c_channel = 0x01;

// Setup SMC I2C
i2c_init(i2c_clock, i2c_channel);

// Pulse the OFFIndicator via SMC
onoff_write(0x1F);

u32 iop2x_val = *(u32 *)LT_IOP2X;

// Adjust IOP clock multiplier
if (iop2x_val & 0x04)
{
   // Enable IRQ 12 (LT)
   *(u32 *)LT_ARMIRQFLAGLT = 0x1000;
   *(u32 *)LT_ARMIRQMASKLT = 0x1000;

   // Switch the multiplier back to 1x
   *(u32 *)LT_IOP2X = 0x01;

   // Wait for hardware interrupt
   sub_D40C870();

   // Disable IRQ 12 (LT)
   *(u32 *)LT_ARMIRQMASKLT = 0;
}

u32 get_hw_ver_res = get_hw_version(hw_ver_buf);

// Failed to get the hardware version
if (get_hw_ver_res)
{
   // Write the error message in the stack
   printf("BOOT1_FAIL: Unable to get ASIC version. (0x1F)");

   // Flash the NDEV_LED with the error code
   send_ndev_led(0xF1);

   // Deadlock
   loc_D400A3A();
}

u32 hw_ver = *(u32 *)hw_ver_buf;

// Hardware is not Latte
if (!(hw_ver & 0x0F000000))
{
   // Write the error message in the stack
   printf("BOOT1_FAIL: NOT supported hardware version. (0x1F)");

   // Flash the NDEV_LED with the error code
   send_ndev_led(0xF1);

   // Deadlock
   loc_D400A3A();
}

// Hardware is Latte A11 or A12
if ((hw_ver >> 0x18) == 0x21)
{
   // Write the error message in the stack
   printf("BOOT1_FAIL: NOT supported hardware version. (0x1F)");

   // Flash the NDEV_LED with the error code
   send_ndev_led(0xF1);

   // Deadlock
   loc_D400A3A();
}

u32 get_board_rev_res = get_board_revision(board_rev_buf);
u32 board_rev = *(u32 *)board_rev_buf;

// Failed to get board revision
if (get_board_rev_res)
{
   // Write the error message in the stack
   printf("BOOT1_FAIL: Unable to get board revision. (0x1F)");

   // Flash the NDEV_LED with the error code
   send_ndev_led(0xF1);

   // Deadlock
   loc_D400A3A();
}
```

## get_rtc_events (setups EXI for the RTC and collects events fro RTC_CONTROL0 and 1)
```cpp
// Setup EXI0 for RTC
config_exi_rtc();

u32 RTC_CONTROL0 = 0x21000C00;

// Read RTC_CONTROL0
u32 exi_read_res = exi_read(RTC_CONTROL0, rtc_control0_buf);

// Failed to read
if (exi_read_res)
{
    // Pulse the ONIndicator
    onoff_write(0x13);

    goto init_mem;
}

u32 RTC_CONTROL1 = 0x21000D00;

// Read RTC_CONTROL1
u32 exi_read_res = exi_read(RTC_CONTROL1, rtc_control1_buf);

// Failed to read
if (exi_read_res)
{
    // Pulse the ONIndicator
    onoff_write(0x13);

    goto init_mem;
}

u32 debug_val = *(u32 *)LT_DEBUG;
u32 pflags_val = 0;

// Check if the CMPT_RETSTAT0 flag is raised
if (debug_val & 0x04)
   pflags_val = 0x100000;        // Set CMPT_RETSTAT0 power flag

// Check if the CMPT_RETSTAT1 flag is raised
if (debug_val & 0x08)
   pflags_val |= 0x80000;        // Set CMPT_RETSTAT1 power flag

u32 rtc_ctrl0 = *(u32 *)rtc_control0_buf;

// Check if the POFFLG_FPOFF flag is raised
if (rtc_ctrl0 & 0x04000000)
   pflags_val |= 0x01000000;     // Set POFF_FORCED power flag

// Check if the POFFLG_4S flag is raised
if (rtc_ctrl0 & 0x02000000)
   pflags_val |= 0x00800000;     // Set POFF_4S power flag

// Check if the POFFLG_TMR flag is raised
if (rtc_ctrl0 & 0x01000000)
   pflags_val |= 0x00400000;     // Set POFF_TMR power flag

// Check if the PONLG_TMR flag is raised
if (rtc_ctrl0 & 0x00010000)
   pflags_val |= 0x02000000;     // Set PON_TMR power flag

// Check if PONFLG_SYS is raised
if (rtc_ctrl0 & 0x00020000)
{
   pflags_val |= 0x04000000;     // Set PON_SMC power flag

   // Read the SystemEventFlag from SMC
   sub_D400BD0(0x41, sys_event_buf);

   u32 sys_event = *(u32 *)sys_event_buf;

   // POWER button was pressed
   if (sys_event & 0x00000040)
      pflags_val |= 0x80000000;  // Set PON_POWER_BTN power flag

   // EJECT button was pressed
   if (sys_event & 0x00000020)
      pflags_val |= 0x40000000;  // Set PON_EJECT_BTN power flag

   // Wake 1 signal is active
   if (sys_event & 0x00000001)
      pflags_val |= 0x08000000;  // Set PON_WAKEREQ1_EVENT power flag

   // Wake 0 signal is active
   if (sys_event & 0x00000002)
      pflags_val |= 0x10000000;  // Set PON_WAKEREQ0_EVENT power flag

   // BT interrupt request is active
   if (sys_event & 0x00000004)
      pflags_val |= 0x20000000;  // Set PON_WAKEBT_EVENT power flag

   // Timer signal is active
   if (sys_event & 0x00000008)
      pflags_val |= 0x00020000;  // Set PON_SMC_TIMER power flag
}

// Raise POFFLG_TMR, PONFLG_SYS and some unknown flags
exi_write(RTC_CONTROL0, 0x01C20000);

u32 rtc_ctrl1 = *(u32 *)rtc_control1_buf;

// Check if SLEEP_EN is raised
if (rtc_ctrl1 & 0x00000100)
   pflags_val |= 0x00200000;     // Set DDR_SREFRESH power flag

u32 mem_mode = 0;

// DDR_SREFRESH power flag is set
if (pflags_val & 0x00200000)
    mem_mode = 0x08;

// PON_SMC_TIMER power flag is set
if (pflags_val & 0x00020000)
{
   // Pulse the CCIndicator
   onoff_write(0x16);

   mem_mode |= 0x02;

   // Set FanSpeed state
   sub_D405570(0);
}
else
{
   // Pulse the ONIndicator
   onoff_write(0x13);
}
```

## init_mem (initializes the memory controller)
```cpp
// Initialize memory
u32 mem_init_res = sub_D4056E8(mem_mode);

// Failed to initialize memory
if (mem_init_res)
{
   // Write the error message in the stack
   printf("BOOT1_FAIL: Unable to initialize memory (0x2F)");

   // Flash the NDEV_LED with the error code
   send_ndev_led(0xF2);

   // Deadlock
   loc_D400A3A();
}
```

## mem2_test (tests MEM2 by writing over it's first 0x400 bytes)
```
u32 error_flag = 0;
u32 error_count = 0;

// Memory is not refreshing
if (error_count)
{
   // DDR_SREFRESH power flag is set
   if (pflags_val & 0x00200000)
   {
      // Check memory
      u32 mem_check_res = sub_D4056B0(mem_mode | 0x60 | 0x04);
      error_flag += mem_check_res;
   }
   else
      error_flag = 0;

   // Check memory
   u32 mem_check_res = sub_D4056B0(mem_mode | 0x60 | 0x08);
   error_flag |= mem_check_res;

   // Failed to setup memory
   if (error_flag != 0)
   {
      // Flash the NDEV_LED with the error code
      send_ndev_led(0xF2);

     // Deadlock
     loc_D400A3A();
   }

   u32 mem2_addr = 0x10000000;

   // Set random data in MEM2 region
   while (mem2_addr != 0x10000400)
   {
      *(u32 *)mem2_addr = 0x12345678;
      *(u32 *)(mem2_addr + 0x04) = 0x9ABCDEF0;

      mem2_addr += 0x08;
   }
}
```

## mem2_check (checks if MEM2 refreshing is working)
```cpp
u32 byte_count = 0xFF;
u32 mem2_test_pattern0 = *(u32 *)mem2_addr;
u32 mem2_test_pattern1 = *(u32 *)(mem2_addr + 0x04);

// Memory has not refreshed
if (mem2_test_pattern0 != 0x12345678)
{
   // Increase error count
   error_count++;

   if (error_count < 0x10)
      goto mem2_test;
   else
   {
      // Deadlock
      loc_D400A3A();
   }
}

// Memory has not refreshed
if (mem2_test_pattern1 != 0x9ABCDEF0)
{
   if (byte_count)
   {
      // Increase error count
      error_count++;

      if (error_count < 0x10)
         goto mem2_test;
      else
      {
         // Deadlock
         loc_D400A3A();
      }
   }
}

byte_count -= 0x02;

// Loop until all memory is checked
if (mem2_addr != 0x100003F8)
{
   mem2_addr -= 0x08;
   goto mem2_check;
}

// Too many errors
if (error_count == 0x10)
{
   // Deadlock
   loc_D400A3A();
}
```

## mem0_clear (clears all MEM0 and adjusts IOP clock multiplier if necessary)
```cpp
// Clear all MEM0
memset(0x08000000, 0, 0x002E0000);

// PON_SMC_TIMER power flag is not set
if (!(pflags_val & 0x00020000))
{
   // Change NDEV_LED state
   *(u32 *)(0x0D40E258) = ~(0x80);

    u32 iop2x_val = *(u32 *)LT_IOP2X;

    // Check if the clock multiplier hasn't been changed
    if (!(iop2x_val & 0x04))
    {
       // Enable IRQ 12 (LT)
       *(u32 *)LT_ARMIRQFLAGLT = 0x1000;
       *(u32 *)LT_ARMIRQMASKLT = 0x1000;

       // Change IOP clock multiplier to 3x
       *(u32 *)LT_IOP2X = 0x03;

       // Wait for hardware interrupt
       sub_D40C870();

       // Disable IRQ 12 (LT)
       *(u32 *)LT_ARMIRQMASKLT = 0;
    }
}
```

## get_boot_info (decrypts PRSH/PRST from MEM2 and parses the boot_info structure)
```cpp
// Send NDEV_LED marker
send_ndev_led(0x31);

// Store something in MEM1
*(u32 *)0x0000000C = 0x20008000;

// Read security level flag from OTP
ReadOTP(0x20, sec_lvl_buf, 0x04);

u32 sec_lvl = *(u32 *)sec_lvl_buf;

bool use_crypto = false;

// We are in retail/debug mode
if (sec_lvl < 0)
{
   // Read Wii U Starbuck ancast key from OTP
   ReadOTP(0x24, 0x0D40E240, 0x10);

   // Store a pointer to the ancast key
   *(u32 *)0x0D40E250 = ancast_key_addr;

   // Store a pointer to the ancast modulus
   *(u32 *)0x0D40E254 = ancast_modulus_addr;

   use_crypto = true;
}

// Decrypt PRSH/PRST with Starbuck ancast key
sub_D400320(0x10000400, 0x7C00, prsh_iv_buf);

// Parse PRSH/PRST
sub_D40B030(0x10000400, 0x7C00);

// Locate or create new "boot_info"
sub_D40AF10(0);

// DDR_SREFRESH power flag is set
if ((pflags_val & 0x01E00001) == 0x00200000)
{
   *(u32 *)boot_info_08_addr = 0;

   // Read from boot_info + 0x08
   u32 result = sub_D40AB84(boot_info_08_addr);

   // Got boot_info_08
   if (result == 0)
   {
      u32 boot_info_08 = *(u32 *)boot_info_08_addr;
      pflags_val |= (boot_info_08 & 0x101E);
   }
}
else
{
   // Mask boot_info_04 with 0xBFFFFFFF
   sub_D40AE4C();

   // Mask boot_info_04 with 0xF7FFFFFF and set some other fields
   sub_D40AC7C();
}

// Set boot_info_08
sub_D40AC30(pflags_val);
```

## load_fw_img (loads/validates/decrypts the IOSU fw.img file)
```cpp
// Get timer value
u32 time_before_fw_load = *(u32 *)HW_TIMER;

// Load fw.img
u32 fw_load_res = sub_D4017B0(use_crypto);

if (fw_load_res)
{
   // Write the error message in the stack
   printf("BOOT1_FAIL: Unable to load firmware.\n");

   // Deadlock
   loc_D400A3A();
}

// Get timer value
u32 time_after_fw_load = *(u32 *)HW_TIMER;

u32 time_fw_verify = 0;
u32 time_fw_decrypt = 0;

if (use_crypto)
{
   // Get timer value
   u32 time_before_fw_verify = *(u32 *)HW_TIMER;

   // Initialize SHA-1 engine 1 (SHA)
   sub_D40C878(0x01);

   // Copy ancast signature (from ancast_hdr + 0x20 to ancast_hdr + 0x1A0)
   memcpy(0x0D40E000, 0x01000020, 0x180);

   // Copy ancast hash block (from ancast_hdr + 0x1A0 to ancast_hdr + 0x200)
   memcpy(0x0D40E180, 0x010001A0, 0x60);

   u32 ancast_img_size = *(u32 *)0x0D40E18C;

   // Check ancast image size
   if (ancast_img_size > 0x00F80000)
       printf("BOOT1: Firmware image of size 0x%x is too big.", ancast_img_size);
   else
       printf("BOOT1: Loaded firmware image size is 0x%x.", ancast_img_size);

   if (board_rev >= 0x04)
   {
       u32 ancast_version = *(u32 *)0x0D40E1A4;

       // Version is too old
       if (ancast_version <= 0x01)
       {
           printf("BOOT1_FAIL: Not able to boot older SDK.");
           printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

           // Flash the NDEV_LED with the error code
           send_ndev_led(0xF6);

           // Deadlock
           loc_D400A3A();
       }
   }

   // Clear up the SHA-1 context
   memset(sha_ctx_buf, 0, 0x18);

   // Calculate empty hash
   u32 sha_calc_res = sha_calc(0x01, 0x00, 0x00, sha_ctx_buf);

   // Failed to calculate
   if (!sha_calc_res)
   {
       // Send execution stage marker
       send_ndev_led(0x41);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   // Clear up the SHA-1 context
   memset(sha_ctx_buf, 0, 0x18);

   // Setup the SHA-1 context
   *(u32 *)sha_ctx_buf = sha_ctx_buf + 0x18;      // end
   *(u32 *)(sha_ctx_buf + 0x04) = 0x02;           // mode (final)
   *(u32 *)(sha_ctx_buf + 0x08) = 0x0D40E180;     // in_buf
   *(u32 *)(sha_ctx_buf + 0x0C) = 0x60;           // in_size
   *(u32 *)(sha_ctx_buf + 0x10) = 0x0D40E200;     // out_buf
   *(u32 *)(sha_ctx_buf + 0x14) = 0x14;           // out_size

   // Calculate the ancast_hash_blk hash
   sha_calc_res = sha_calc(0x01, 0x00, 0x00, sha_ctx_buf);

   // Failed to calculate
   if (!sha_calc_res)
   {
       // Send execution stage marker
       send_ndev_led(0x42);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   u32 ancast_header_addr = 0x0D40E000;
   u32 rsa_exponent_addr = 0x0D40DC00;
   u32 ancast_hash_addr = 0x0D40E200;
   u32 ancast_modulus_addr = *(u32 *)0x0D40E254;

   // Calculate ancast image signature
   u32 rsa_calc_res = rsa_calc(ancast_hash_addr, ancast_modulus_addr, ancast_header_addr + 0x04, rsa_exponent_addr, 0x04);

   // Failed to calculate
   if (rsa_calc_res)
   {
       // Send execution stage marker
       send_ndev_led(0x43);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   u16 ancast_header_1A0 = *(u32 *)0x0D40E180;

   // This field must be NULL
   if (ancast_header_1A0)
   {
       // Send execution stage marker
       send_ndev_led(0x44);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   u8 ancast_header_1A2 = *(u32 *)0x0D40E182;

   // This field must be NULL
   if (ancast_header_1A2)
   {
       // Send execution stage marker
       send_ndev_led(0x45);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   u8 ancast_header_1A3 = *(u32 *)0x0D40E183;

   // This field must be NULL
   if (ancast_header_1A3)
   {
       // Send execution stage marker
       send_ndev_led(0x45);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   u32 ancast_header_1C8_start_addr = 0x0D40E1A8;
   u32 ancast_header_1C8_end_addr = 0x0D40E1E0;

   // Last 0x38 bytes in the ancast header must be NULL
   while (ancast_header_1C8_start_addr != ancast_header_1C8_end_addr)
   {
       u32 ancast_header_unk = *(u32 *)ancast_header_1C8_start_addr;

       // Must be NULL
       if (ancast_header_unk)
       {
          // Send execution stage marker
          send_ndev_led(0x46);

          printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

          // Flash the NDEV_LED with the error code
          send_ndev_led(0xF6);

          // Deadlock
          loc_D400A3A();
       }

       ancast_header_1C8_start_addr++;
   }

   u32 ancast_img_body_size = *(u32 *)0x0D40E18C;
   u32 ancast_img_body_block_count = (ancast_img_body_size >> 0x0C);

   // Bad image size
   if (!ancast_img_body_block_count)
   {
       // Send execution stage marker
       send_ndev_led(0x48);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   // Bad image size alignment
   if (ancast_img_body_size & 0x00000FFF)
   {
       // Send execution stage marker
       send_ndev_led(0x48);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   // Initialize SHA-1 engine 1 (SHA)
   sub_D40C878(0x01);

   // Clear up the SHA-1 context
   memset(sha_ctx_buf, 0, 0x18);

   // Calculate empty hash
   sha_calc_res = sha_calc(0x01, 0x00, 0x00, sha_ctx_buf);

   // Failed to calculate
   if (!sha_calc_res)
   {
       // Send execution stage marker
       send_ndev_led(0x49);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   u32 block_count = 0;
   u32 ancast_img_body_addr = 0x01000200;

   // Calculate the ancast image body hash
   while (block_count < ancast_img_body_block_count)
   {
       // Clear up the SHA-1 context
       memset(sha_ctx_buf, 0, 0x18);

       // Setup the SHA-1 context
       *(u32 *)sha_ctx_buf = sha_ctx_buf + 0x18;            // end
       *(u32 *)(sha_ctx_buf + 0x04) = 0x01;                 // mode (update)
       *(u32 *)(sha_ctx_buf + 0x08) = ancast_img_body_addr; // in_buf
       *(u32 *)(sha_ctx_buf + 0x0C) = 0x1000;               // in_size
       *(u32 *)(sha_ctx_buf + 0x10) = 0x0D40E200;           // out_buf
       *(u32 *)(sha_ctx_buf + 0x14) = 0x14;                 // out_size

       // Calculate (update) ancast body hash (0x1000 bytes at a time)
       sha_calc_res = sha_calc(0x01, 0x00, 0x00, sha_ctx_buf);

       // Failed to calculate
       if (!sha_calc_res)
       {
          // Send execution stage marker
          send_ndev_led(0x4A);

          printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

          // Flash the NDEV_LED with the error code
          send_ndev_led(0xF6);

          // Deadlock
          loc_D400A3A();
       }

       block_count++;
       ancast_img_body_addr += 0x1000;
   }

   // Clear up the SHA-1 context
   memset(sha_ctx_buf, 0, 0x18);

   // Setup the SHA-1 context
   *(u32 *)sha_ctx_buf = sha_ctx_buf + 0x18;           // end
   *(u32 *)(sha_ctx_buf + 0x04) = 0x02;                // mode (final)
   *(u32 *)(sha_ctx_buf + 0x08) = 0;                   // in_buf
   *(u32 *)(sha_ctx_buf + 0x0C) = 0;                   // in_size
   *(u32 *)(sha_ctx_buf + 0x10) = 0x0D40E200;          // out_buf
   *(u32 *)(sha_ctx_buf + 0x14) = 0x14;                // out_size

   // Calculate ancast body hash
   sha_calc_res = sha_calc(0x01, 0x00, 0x00, sha_ctx_buf);

   // Failed to calculate
   if (!sha_calc_res)
   {
       // Send execution stage marker
       send_ndev_led(0x4A);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   u32 body_hash_addr = 0x0D40E200;
   u32 ancast_body_hash_addr = 0x0D40E190;

   // Compare generated hash with the hash in the ancast header
   u32 memcmp_res = memcmp(ancast_body_hash_addr, body_hash_addr, 0x14);

   // Hashes don't match
   if (memcmp_res)
   {
       // Send execution stage marker
       send_ndev_led(0x4B);

       printf("BOOT1_FAIL: Unable to authenticate firmware image (0x6F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF6);

       // Deadlock
       loc_D400A3A();
   }

   // Get timer value
   u32 time_after_fw_verify = *(u32 *)HW_TIMER;
   u32 time_before_fw_decrypt = *(u32 *)HW_TIMER;

   u32 starbuck_ancast_iv_addr = 0x0D40DAC0;

   // Decrypt Starbuck ancast image
   u32 decrypt_res = sub_D400320(ancast_img_body_addr, ancast_img_body_size, starbuck_ancast_iv_addr);

   // Failed to decrypt
   if (!decrypt_res)
   {
       printf("BOOT1_FAIL: Unable to decrypt firmware image (0x7F).");

       // Flash the NDEV_LED with the error code
       send_ndev_led(0xF7);

       // Deadlock
       loc_D400A3A();
   }

   // Calculate time spent verifying fw.img
   u32 time_fw_verify = (time_before_fw_verify - time_after_fw_verify);

   // Get timer value
   u32 time_after_fw_decrypt = *(u32 *)HW_TIMER;

   // Calculate time spent decrypting fw.img
   u32 time_fw_decrypt = (time_after_fw_decrypt - time_before_fw_decrypt);
}
```

## Cleanup (clears all sensitive data from memory, locks out two blocks in the OTP and turns on the ODD)
```cpp
// Clear Wii U Starbuck ancast key from memory
memset(0x0D40E240, 0, 0x10);

// Clear the exponent from memory
memset(0x0D40DC00, 0, 0x04);

// Clear the RSA modulus from memory
memset(0x0D40DB00, 0, 0x100);

// Clear Wii U Starbuck ancast IV from memory
memset(0x0D40DAC0, 0, 0x10);

// Lock out two additional blocks in the OTP
u32 otpprot_val = *(u32 *)LT_OTPPROT;
otpprot_val &= 0xEF7FFFFF;
*(u32 *)LT_OTPPROT = otpprot_val;

u32 onoff_val = 0;

// PON_SMC_TIMER and an unknown power flag are set
if (pflags_val & 0x00020010)
{
   // Set DcdcPowerControl2 GPIO's state
   sub_D405524(0x00);

   onoff_val = 0x15;
}
else
{
   // Turn on ODDPower via SMC
   onoff_write(0x00);

   // Set DcdcPowerControl2 GPIO's state
   sub_D405524(0x01);

   onoff_val = 0x10;
}

// Turn on the ONIndicator (0x10) or the CCIndicator (0x15)
onoff_write(onoff_val);
```

## Finish (writes the time spent on variouts stages to the "boot_info" structure and jump to the ELF loading stub in the decrypted IOSU fw.img)
```cpp
// Get timer value
u32 time_boot1_end = *(u32 *)HW_TIMER;

// Calculate time spent running boot1
u32 time_boot1 = (time_boot1_end - time_boot1_start);

// Write to boot_info_38
sub_D40AD2C(0x00, time_boot1);

// Calculate time spent reading fw.img
u32 time_fw_load = (time_before_fw_verify - time_before_fw_load)

// Write to boot_info_3C
sub_D40AD2C(0x01, time_fw_load);

// Write to boot_info_40
sub_D40AD2C(0x02, time_fw_verify);

// Write to boot_info_44
sub_D40AD2C(0x03, time_fw_decrypt);

// Read times stored by boot0
u32 time_boot0 = *(u32 *)0x0D417FE0;
u32 time_boot1_load = *(u32 *)0x0D417FE4;
u32 time_boot1_verify = *(u32 *)0x0D417FE8;
u32 time_boot1_decrypt = *(u32 *)0x0D417FEC;

// Write to boot_info_48
sub_D40AD2C(0x04, time_boot0);

// Write to boot_info_4C
sub_D40AD2C(0x05, time_boot1_load);

// Write to boot_info_50
sub_D40AD2C(0x06, time_boot1_verify);

// Write to boot_info_54
sub_D40AD2C(0x07, time_boot1_decrypt);

// Set flag 0x04000000 in boot_info_04
sub_D40ABCC();

// Increase boot_info_0C by 1
sub_D40AEB0();

printf("BOOT1: Starting firmware relocator.\n");

// Flash the NDEV_LED with the status code
send_ndev_led(0x88);

// Jump to IOSU's ELF loader
sub_0x01000300();

// Deadlock
loc_D400A3A();
```

# Error codes
| Error code | Notes                                 |
| :--------: | :------------------------------------ |
|    0xF1    | Invalid hardware version              |
|    0xF2    | Failed to initialize memory           |
|    0xF6    | Failed to authenticate firmware image |
|    0xF7    | Failed to decrypt firmware image      |