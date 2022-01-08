# 0xffff'0000
```cpp
memset_range(0x0D417FE0, 0x0D417FF0, 0, 0x04);

memcpy(0x0D4100A0, 0xFFFF00A0, 0x3680);

LR = 0xFFFF004C
PC = sub_D4100A0

// Deadlock
loc_D41004C();
```

# Setup (sub_D4100A0)
```cpp
// Invalidate ICache
MCR p15, 0, R0, c7, c5, 0

// Invalidate DCache
MCR p15, 0, R0, c7, c6, 0

// Read control register
MRC p15, 0, R0,c1,c0, 0

// Set replacement strategy to Round-Robin
r0 = r0 | 0x1000

// Write control register
MCR p15, 0, R0,c1,c0, 0

// Clear 0x351C bytes after boot0
memset_range(0x0D413720, 0x0D416C3C, 0, 0x04);

// Set stack pointer
SP = 0x0D414204 + 0x1000

// Set return address
LR = sub_D4100F8		// Jump to boot1
PC = sub_D410384		// boot0 main
```

# Main
## Start
```cpp
// Get timer value
u32 time_now = *(u32 *)HW_TIMER;

// Set start time
*(u32 *)0x0D413768 = 0;
```

## 0x00 (set flag HW_SPARE1, configure debug ports)
```
// Send debug mark
SendGPIODebugOut(0x00);

u32 spare1_val = *(u32 *)HW_SPARE1;

// Set something in HW_SPARE1
*(u32 *)HW_SPARE1 = spare1_val | 0xC0;

// Enable GPIO for debug ports
u32 gpio_enable_val = *(u32 *)HW_GPIO_ENABLE;
*(u32 *)HW_GPIO_ENABLE = gpio_enable_val | 0x00FF0000;

// Set direction to output
u32 gpio_dir_val = *(u32 *)HW_GPIO_DIR;
*(u32 *)HW_GPIO_DIR = gpio_dir_val | 0x00FF0000;
```

## 0x01 (memory swap)
```cpp
// Send debug mark
SendGPIODebugOut(0x01);

// Set memory swap
*(u32 *)HW_SRNPROT = 0x07;
```

## 0x02 (AEC)
```cpp
// Send debug mark
SendGPIODebugOut(0x02);

*(u32 *)AES_CTRL = 0;
*(u32 *)AES_KEY = 0;
*(u32 *)AES_KEY = 0;
*(u32 *)AES_KEY = 0;
*(u32 *)AES_KEY = 0;
*(u32 *)AES_IV = 0;
*(u32 *)AES_IV = 0;
*(u32 *)AES_IV = 0;
*(u32 *)AES_IV = 0;
*(u32 *)AES_SRC = 0;
*(u32 *)AES_DEST = 0;
```

## 0x03 (SHA-1)
```cpp
// Send debug mark
SendGPIODebugOut(0x03);

*(u32 *)SHA_CTRL = 0;
*(u32 *)SHA_H0 = 0;
*(u32 *)SHA_H1 = 0;
*(u32 *)SHA_H2 = 0;
*(u32 *)SHA_H3 = 0;
*(u32 *)SHA_H4 = 0;
*(u32 *)SHA_SRC = 0;
```

## 0x04 (LT_AHBCMPT, enable OTP reading)
```cpp
// Send debug mark
SendGPIODebugOut(0x04);

// Set something in AHB compat
u32 ahb_val = *(u32 *)LT_AHBCMPT;
*(u32 *)LT_AHBCMPT = (ahb_val & 0xFFFFF3FF) | 0xC00;

// Enable OTP reading
SetOTPReadCommand();
```

## 0x05, 0x06, 0x07 (reset/enable EXI)
```cpp
// Send debug mark
SendGPIODebugOut(0x05);

// Assert RSTB_IOPI
u32 resets = *(u32 *)HW_RSTB;
*(u32 *)HW_RSTB = resets | 0x80000;

// Assert RSTB_IOMEM
u32 resets = *(u32 *)HW_RSTB;
*(u32 *)HW_RSTB = resets | 0x40000;

// Enable EXI
u32 aip_prot = *(u32 *)HW_AIP_PROT;
*(u32 *)HW_AIP_PROT = aip_prot | 0x01;
```

## 0x08 (reads all it needs from the OTP)
```cpp
// Send debug mark
SendGPIODebugOut(0x08);

// Read security level flag from OTP
ReadOTP(0x20, 0x0D413760, 0x04);

// Read IOStrength flags from OTP
ReadOTP(0x21, 0x0D41375C, 0x04);

// Read SEEPROM pulse length from OTP
ReadOTP(0x22, 0x0D413758, 0x04);

// Read SEEPROM key from OTP
ReadOTP(0x28, 0x0D41376C, 0x10);

// Read boot1 key from OTP
ReadOTP(0xE8, 0x0D41377C, 0x10);
```

## 0x09 (analyze IOStrength and sets the srength of various devices)
```cpp
// Send debug mark
SendGPIODebugOut(0x09);

// Setup devices' strength
u32 iostrength_flags = *(u32 *)0x0D41375C;
u32 iostrength_ctrl0_val = *(u32 *)HW_IOSTRCTRL0;
u32 iostrength_ctrl1_val = *(u32 *)HW_IOSTRCTRL1;

if (((iostrength_flags >> 0x0F) & 0x01) != 0)
{
    iostrength_ctrl0_val &= 0xFFFC7FFF;
    iostrength_ctrl0_val |= ((iostrength_flags << 0x11) >> 0x1D) << 0x0F;
}

*(u32 *)HW_IOSTRCTRL0 = iostrength_ctrl0_val;

if (((iostrength_flags >> 0x0F) & 0x01) != 0)
{
    iostrength_ctrl1_val &= 0xFFFC7FFF;
    iostrength_ctrl1_val |= (iostrength_flags & 0x07) << 0x0F;
}

if (((iostrength_flags >> 0x07) & 0x01) != 0)
{
    iostrength_ctrl1_val &= 0xFFE3FFFF;
    iostrength_ctrl1_val |= ((iostrength_flags << 0x19) >> 0x1D) << 0x12;
}

if (((iostrength_flags >> 0x0B) & 0x01) != 0)
{
    iostrength_ctrl1_val &= 0xFFFF8FFF;
    iostrength_ctrl1_val |= ((iostrength_flags << 0x15) >> 0x1D) << 0x0C;
}

if (((iostrength_flags >> 0x13) & 0x01) != 0)
{
    iostrength_ctrl1_val &= 0xFFFF8FFF;
    iostrength_ctrl1_val |= ((iostrength_flags << 0x0D) >> 0x1D) << 0x15;
}

*(u32 *)HW_IOSTRCTRL1 = iostrength_ctrl1_val;
```

## 0x0A (set SEEPROM's pulse length, configures SEEPROM GPIOs)
```cpp
// Send debug mark
SendGPIODebugOut(0x0A);

u32 seeprom_pulse = *(u32 *)0x0D413758;

// Set default value (retail)
if (seeprom_pulse == 0)
   seeprom_pulse = 0xFA;

// Store pulse value at 0x0D413460
sub_D411774();

// Configure SEEPROM GPIOs
Set_SEEPROM_GPIO();
```

## 0x0B(analyses the OTP security level flag, decides which keys to use)
```cpp
// Send debug mark
SendGPIODebugOut(0x0B);

u32 sec_lvl_flag = *(u32 *)0x0D413760;

// Forcefully throw error
if (sec_lvl_flag == 0x40000000)
   throw_error();

// Factory mode
if (sec_lvl_flag == 0x00000000)
    set_empty_aes_keys();
else
{
    // Disable boot1 AES key access
    u32 otpprot_val = *(u32 *)LT_OTPPROT;
    *(u32 *)LT_OTPPROT = otpprot_val & 0xDFFFFFFF;

    // This is a devkit unit
    if ((sec_lvl_flag & 0x18000000) == 0x08000000)
        set_debug_aes_keys();
    else if ((sec_lvl_flag & 0x10000000) == 0x10000000)  // This is a retail unit
        set_retail_aes_keys();
    else
        throw_error();
}
```

## 0x0C (generates a CRC32 table in stack)
```cpp
// Send debug mark
SendGPIODebugOut(0x0C);

// Generate CRC32 table from
// 0x0D413D44 to 0x0D414140
CRC32_Gen();
```

## 0x0D (decrypt seeprom)
```cpp
// Send debug mark
SendGPIODebugOut(0x0D);

// Set SEEPROM AES key
AES_Set_Key(aes_seeprom_key);

// Read and decrypt from SEEPROM
SEEPROM_Read(0x1C, 0x0D41378C, 0x01);

// Read and decrypt from SEEPROM
SEEPROM_Read(0x1D, 0x0D41379C, 0x01);

// Read and decrypt from SEEPROM
SEEPROM_Read(0x1E, 0x0D4137AC, 0x01);
```


## 0x0E (validates seeprom(0x1C0)'s data use crc32, )
```cpp
// Send debug mark
SendGPIODebugOut(0x0E);

// Factory mode uses an empty SEEPROM key
if (!aes_seeprom_key)
{
   // Match CRC32 with the table
   // CRC32 is at seeprom_1C + 0x0C
   bool match = sub_D410168(seeprom_1C, 0x10);

   // CRC32 didn't match, but we are in factory
   // mode, so we just set everything to 0
   if (!match)
      memset(seeprom_1C, 0, 0x10);
}
else   // Normal mode has a valid SEEPROM key
{
   // Match CRC32 with the table
   // CRC32 is at seeprom_1C + 0x0C
   bool match = sub_D410168(seeprom_1C, 0x10);

   // CRC32 didn't match, throw an error
   if (!match)
      throw_error();
}

// Read SEEPROM boot flags
u16 seeprom_1C_00 = *(u16 *)0x0D41378C;
u16 seeprom_1C_02 = *(u16 *)0x0D41378C + 0x02;
u32 seeprom_1C_04 = *(u32 *)0x0D41378C + 0x04;
u32 seeprom_1C_08 = *(u32 *)0x0D41378C + 0x08;

// Factory mode doesn't need boot1's data
if (!aes_seeprom_key)
{
   boot1_version = 0;
   boot1_sector = 0;
}
```

## 0x0F (validates seeprom(0x1D0, 0x1E0))
- this data is used to determine boot1's version
- **skipped in factory mode**
```cpp
// Send debug mark
SendGPIODebugOut(0x0F);

// Match CRC32 with the table
// CRC32 is at seeprom_1D + 0x0C
bool match1 = sub_D410168(seeprom_1D, 0x10);

// Match CRC32 with the table
// CRC32 is at seeprom_1E + 0x0C
bool match2 = sub_D410168(seeprom_1E, 0x10);

// Both sections have invalid CRC32
if (!match1 && !match2)
   throw_error();

// The SEEPROM specifies the versions and sectors
// of the two boot1 images stored in the NAND
u16 boot1_version1 = (u16)seeprom_1D;
u16 boot1_version2 = (u16)seeprom_1E;
u16 boot1_sector1 = (u16)seeprom_1D + 0x02;
u16 boot1_sector2 = (u16)seeprom_1E + 0x02;

// The second version is always the most recent
u16 boot1_version = (boot1_version2 > boot1_version1) ? boot1_version2 : boot1_version1;
u16 boot1_sector = (boot1_version2 > boot1_version1) ? boot1_sector2 : boot1_sector1;

// Check if seeprom_1C_00 is not 0x400
if ((seeprom_1C_00 & 0x3FF) != 0)
{
   // Store at 0x0D414200
   sub_D41203C(seeprom_1C_00 & 0x3FF);
}
```

## 0x10, 0x11, 0x12 (configures starbuck's clock multiplier)
- flag: SEEPROM(0x1C0) 2-byte flag in negative value
```cpp
// Send debug mark
SendGPIODebugOut(0x10);

// Allow IRQ 12 (LT)
*(u32 *)LT_ARMIRQMASKLT = 0x1000;

// Set the ARM multiplier
*(u32 *)LT_IOP2X = 0x03;

// Wait for interrupt
sub_D4132E8();

// Disable IRQ 12 (LT)
*(u32 *)LT_ARMIRQMASKLT = 0;
```

## 0x13 (analyses remaining data read form SEEPROM(0x1C0) -> uses it to configure the NAND_CONFIG and NAND_BACK registers) => Initializes NAND engine
```cpp
// Send debug mark
SendGPIODebugOut(0x13);

// Use supplied NAND configuration
if (((seeprom_1C_02 >> 0x0E) & 0x01) != 0)
   *(u32 *)NAND_CONFIG = (u32)seeprom_1C_04;

// Use supplied NAND bank
if (((seeprom_1C_02 >> 0x0D) & 0x01) != 0)
   *(u32 *)NAND_BANK = (u32)seeprom_1C_08;

// Determine if boot1 is in SLC or SLCCMPT
bool boot1_isSLC = (boot1_sector >> 0x0C) ? true : false;

// Init NAND
u32 result = sub_D411564(boot1_isSLC);
```

## 0x14 (check start time is valid and saves the current time(in order to track how long boot1's reading took). Ths stage only executes if NAND engine's initialization was successful)
```cpp
// Send debug mark
SendGPIODebugOut(0x14);

// time_at_boot is must be 0
// otherwise throw error
if (time_at_boot != 0)
   throw_error();

// Take note of the current time
u32 boot1_read_time = *(u32 *)LT_TIMER;
```

## 0x15, 0x16, 0x17 (flushes AHB memory, reads boot1's ancast header from NAND and checks one size by looking into respective field inside the header. If the size is valid (must not exceed 0xF800, so it doesn't overflow boot1's memory region), boot0 then proceeds to read the ful boot1's image from NAND into address 0x0D400000: Finally boot0 calculates how long this operation took and stores this value for the IOS-mCP to read later on. These stages ony execute if NAND engine's initialization was successful))
```cpp
// Send debug mark
SendGPIODebugOut(0x15);

// AHB memory flush
ahbMemFlush(0);

// Bit 15 in seeprom_1C_02 tells to ignore NAND errors
bool ignore_errors = ((seeprom_1C_02 >> 0x0F) & 0x01) ? true : false;

// Read boot1's header from NAND into 0x0D400000
u32 result = NAND_Read(0x0D400000, boot1_sector << 0x06, 0x01, ignore_errors);

// Failed to read from NAND
if (!result)
   throw_error();

// Copy the last 0x60 bytes of
// boot1's ancast image's header
memcpy(0x0D413940, 0x0D4001A0, 0x60);

// Check ancast image's body size
u32 ancast_body_size = *(u32 *)0x0D41394C;

// Calculate boot1's actual size
u32 boot1_image_size = ((ancast_body_size + 0x9FF) & 0xFFFFF800) - 0x01;

// The image is too big
if (boot1_image_size > 0xF7FF)
   throw_error();

// AHB memory flush
ahbMemFlush(0);

// Read the full boot1 image
result = NAND_Read(0x0D400000, boot1_sector << 0x06, boot1_image_size >> 0x0B, ignore_errors);

// Failed to read from NAND
if (!result)
   throw_error();

// Calculate how long it took to
// read boot1 (MCP later reads this)
u32 time_now = *(u32 *)HW_TIMER;
*(u32 *)0x0D417FE4 = time_now - boot1_read_time;
```


## 0x18 (checks boot1 encrypted. This stage only executes if NAND engine's initialization was successful)
```cpp
// Send debug mark
SendGPIODebugOut(0x18);

// No need to decrypt in factory mode
if (!aes_boot1_key)
   goto skip_boot1_decrypt;
```

## 0x19 (verifies boot1's hash and signature. if NAND engine initialize was successful &not factory mode)
```cpp
// Send debug mark
SendGPIODebugOut(0x19);

// Hash and verify boot1's image
u32 image_blocks = Calc_SHA1_RSA(0, 0x0D400000);

// Failed to verify
if (image_blocks == 0)
   throw_error();
```

## 0x1A (decrypts bot1 in place, if NAND engine initialize was successful &not factory mode)
```cpp
// Send debug mark
SendGPIODebugOut(0x1A);

// Decrypt boot1
AES_Decrypt(boot1_key, 0x0D400000, image_blocks);
```

## 0x1B (determinate how long it should wait before attempting to initialize the SD card host)
```cpp
// Send debug mark
SendGPIODebugOut(0x1B);

// Delay execution arbitrarily
if ((seeprom_1C_00 & 0x7C00) != 0)
{
   u32 time_now = *(u32 *)HW_TIMER;

   // Delay in multiples of 10000 ms
   u32 seeprom_delay = (u32)(seeprom_1C_00 >> 0x0A) * 0x2710;

   // Calculate delay
   u32 delay = sub_D412060(seeprom_delay);

   while (time_now < delay)
   {
      time_now = *(u32 *)HW_TIMER;
      delay = sub_D412060(seeprom_delay);
   }
}
```

## 0x1C (initializes EXI)
```cpp
// Send debug mark
SendGPIODebugOut(0x1C);

// Assert RSTB_IOEXI
u32 resets = *(u32 *)HW_RSTB;
*(u32 *)HW_RSTB = resets | 0x10000;

// Setup EXI
sub_D410BB8();
```

## 0x1D (read events from RTC use EXI. if UNSTBL_PWR is set in RTC_CONTROL0, boot0 will attempt to load a recovery signed boot1 image from a SD card)
```cpp
// Send debug mark
SendGPIODebugOut(0x1D);

// Request from EXI0
u32 result = sub_D410D78(exi0_out_buf);

// We got a response from EXI0
if (result)
{
   u32 exi0_reply = *(u32 *)exi0_out_buf;

   // UNSTBL_PWR bit is set in RTC_CONTROL0
   if ((exi0_reply << 0x14) < 0)
      load_sd = true;
}

// Nothing to do, skip the next stages
if (!load_sd)
   goto exit;
```

## 0x1E (if EXI told boot0 to load an image from the SD card)
### Flow
- 1
  - configuring the SDC0S0Power GPIO
- 2
  - initializes/configures SD host controller
  - flushes AHB memory and loads the recovery image's ancast header from the SD card
  - It checks the recovery image's by looking at the size field in header
    - must not exceed 0xF800, so it doesn't overflow boot1's memory region
- 3
  - reads in the full image into memory address 0x0D400000
    - replacing what was read from the NAND
### Process
```cpp
// Send debug mark
SendGPIODebugOut(0x1E);

// Disable SDC0S0Power interrupts
u32 gpio_intmask_val = *(u32 *)HW_GPIO_INTMASK;
*(u32 *)HW_GPIO_INTMASK = gpio_intmask_val & 0xBFFFFFFF;

// Set SDC0S0Power GPIO direction to output
u32 gpio_dir_val = *(u32 *)HW_GPIO_DIR;
*(u32 *)HW_GPIO_DIR = gpio_dir_val | 0x40000000;

// Enable SDC0S0Power GPIO
u32 gpio_enable_val = *(u32 *)HW_GPIO_ENABLE;
*(u32 *)HW_GPIO_ENABLE = gpio_enable_val | 0x40000000;

// Clear SDC0S0Power GPIO output
u32 gpio_out_val = *(u32 *)HW_GPIO_OUT;
*(u32 *)HW_GPIO_OUT = gpio_out_val & 0xBFFFFFFF;

// Delay execution arbitrarily again
u32 time_now = *(u32 *)HW_TIMER;

// Delay in multiples of 20000 ms
u32 seeprom_delay = (u32)((seeprom_1C_02 << 0x16) >> 0x1E) * 0x4E20;

// Calculate delay
u32 delay = sub_D412060(seeprom_delay);

while (time_now < delay)
{
   time_now = *(u32 *)HW_TIMER;
   delay = sub_D412060(seeprom_delay);
}

// Initialize host controller
u32 host_id = 0;
u32 reg_offset = 0;
u32 result = sub_D411290(host_id, reg_offset, sd_handle_buf);

// Failed to initialize the controller
if (!result)
   throw_error();

// Grab the handle returned from initialization
u32 sd_handle = *(u32 *)sd_handle_buf;

// It's possible to specify the clock and switch_func
// values for the SD card from flags in the SEEPROM
u32 sd_clk = 0;
u32 sd_switch_func = 0;

u8 seeprom_sd_flag1 = (u8)(seeprom_1C_02 << 0x14);
u8 seeprom_sd_flag2 = (u8)((seeprom_1C_02 << 0x15) >> 0x1F);

// Set the SD card's clock value
if (seeprom_sd_flag1 > 0)
   sd_clk = 0x01;
else
   sd_clk = seeprom_sd_flag1 & 0xFF;

// Set the SD card's switch_func value
// This is passed to SD card CMD6 and can be
// used to turn high speed on
sd_switch_func = seeprom_sd_flag2;

// Setup the SD card
result = sub_D41139C(host_id, reg_offset, sd_handle, sd_clk, sd_switch_func);

// Failed to setup the SD card
if (!result)
   throw_error();

// AHB memory flush
ahbMemFlush(0);

// Read SD recovery image's ancast header
result = sub_D411544(host_id, reg_offset, 0x0D400000, 0x400);

// Failed to read the recovery image's ancast header
if (!result)
   throw_error();

// Copy the last 0x60 bytes of
// boot1's ancast image's header
memcpy(0x0D413940, 0x0D4001A0, 0x60);

// Check ancast image's body size
u32 ancast_body_size = *(u32 *)0x0D41394C;

// Calculate boot1's actual size
u32 boot1_image_size = ((ancast_body_size + 0x3FF) & 0xFFFFF800) - 0x01;

// The image is too big
if (boot1_image_size > 0xF7FF)
   throw_error();

// AHB memory flush
ahbMemFlush(0);

// Read the SD recovery image
result = sub_D411544(host_id, reg_offset, 0x0D400000, boot1_image_size);

// Failed to read the recovery image
if (!result)
   throw_error();
```

## 0x1F (checks recovery image is encrypted. if EXI told boot0 to load an image from the SD card)
```cpp
// Send debug mark
SendGPIODebugOut(0x1F);

// No need to decrypt in factory mode
if (!aes_boot1_key)
   goto skip_boot1_decrypt;
```

## 0x20 (verifies the recovert image's hash and signature. if EXI told boot0 to load an image from the SD card)
```cpp
// Send debug mark
SendGPIODebugOut(0x20);

// Hash and verify boot1's image
u32 image_blocks = Calc_SHA1_RSA(0, 0x0D400000);

// Failed to verify
if (image_blocks == 0)
   throw_error();
```

## 0x21 (decrypts the recovert image. if EXI told boot0 to load an image from the SD card)
```cpp
// Send debug mark
SendGPIODebugOut(0x21);

// Decrypt boot1
AES_Decrypt(boot1_key, 0x0D400000, image_blocks);
```

## 0x25 (clears boot1,SEEPROM keys from memory, calculates and stores how long it took to run and returns)
```cpp
// Send debug mark
SendGPIODebugOut(0x25);

// Clear boot1 key
memset(0x0D41377C, 0, 0x10);

// Clear SEEPROM key
memset(0x0D41376C, 0, 0x10);

// boot1/recovery image start address
r0 = 0x0D400200

// Store boot0's boot time
*(u32 *)0x0D417FE0 = time_now - initial_time;

return;
```

# Load boot1
- execution fall into the pointer that was set in the LR register
- boot0 finishes by setting r0 to 0x0D400200 since returning from boot0 is equivalent to callc sub_D41100F8(0x0D400200)
```cpp
// Jump to boot1
sub_D4100F8(addr)
{
   r1 = addr

   // Read control register
   MRC p15, 0, R0,c1,c0, 0

   // Set replacement strategy to normal
   r0 = r0 & ~(0x1000)

   // Write control register
   MCR p15, 0, R0,c1,c0, 0

   PC = addr
}
```

# Error codes
| Code  | Notes                                                      |
| :---: | :--------------------------------------------------------- |
| 0xC1  | OTP security level flag is 0x40000000                      |
| 0xC2  | OTP security level flag is invalid                         |
| 0xC3  | SEEPROM CRC32 mismatch from data at offset 0x1C0           |
| 0xC4  | SEEPROM CRC32 mismatch from data at offset 0x1D0 and 0x1E0 |
| 0xD1  | Failed to read boot1's ancast header from NAND             |
| 0xD2  | Failed to start SD host controller                         |
| 0xD3  | Failed to setup SD card                                    |
| 0xD4  | Failed to read boot1's ancast header from SD card          |
| 0xD5  | Bad start time during NAND initialization                  |
| 0xD6  | Ancast image size overflow (from NAND)                     |
| 0xD7  | Failed to read boot1 image from NAND                       |
| 0xD8  | Ancast image size overflow (from SD card)                  |
| 0xD7  | Failed to read boot1 image from SD card                    |
| 0xDA  | Failed to initialize NAND engine                           |
```cpp
// Send the error code
SendGPIODebugOut(error_code);

// Clear boot1 key
memset(0x0D41377C, 0, 0x10);

// Clear SEEPROM key
memset(0x0D41376C, 0, 0x10);

// Lock execution and output error code
while (1)
{
   // Output 0x02
   SendGPIODebugOut(0x02);

   // Wait
   UDelay(0x7A120);

   // Output time
   u32 time = *(u32 *)0x0D413768;
   SendGPIODebugOut(time);

   // Wait
   UDelay(0x7A120);

   // Output error code
   u32 gpio_out_val = *(u32 *)HW_GPIO_OUT;
   SendGPIODebugOut((gpio_out_val << 0x08) >> 0x18);

   // Wait
   UDelay(0x7A120);
 }
 ```