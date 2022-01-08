# IOSU
- Input/Output system に U をつけたもの…だと思う
- カーネルあり
  - メモリ管理
  - プロセス,スレッド管理
  - IPC
  - パーミッションの制御
  - etc...?
- ARM user mode でデバイスドライバ,セキュリティハンドラが働く
  - 俗に言うリソースマネージャ(RM)
  - /dev 以下の仮想ファイルシステムでリソース要求ハンドラとして登録できる
  - これらのプロセスは、カーネルを通じて Unix ファイル操作を使って互いに通信する
    - open / close
    - read / write
    - seek
    - ioctl(v)
- システムコールは ARM の未定義ハンドラを介して処理される
  - カーネル関数にマッピング
- 詳しい情報は [https://wiiubrew.org/wiki/IOSU](IOSU) にある

## 補助ベクター
IOSU ELF ファイルの PH_NOTES セクションには "mrg file" と呼ばれるものが含まれています
"mrg file" は IOSU モジュールの補助ベクターを含んでいます

これらのベクタは IOS-KERNEL にモジュール起動前にパースされます

モジュールごとに 6 つの auxv_t があります（5.5.x では 14 個あります）

## 使用されるタイプ
|       Name       | Value |        Description        |
| :--------------: | :---: | :-----------------------: |
|     AT_ENTRY     | 0x09  |    Entry point address    |
|      AT_UID      | 0x0b  |         Module ID         |
|   AT_PRIORITY    | 0x7d  |   Main thread priority    |
|  AT_STACK_SIZE   | 0x7e  |  Main thread stack size   |
|  AT_STACK_ADDR   | 0x7f  | Main thread stack address |
| AT_MEM_PERM_MASK | 0x80  |                           |

## 実際の情報

| AT_UID |  AT_ENTRY  | AT_PRIORITY | AT_STACK_SIZE | AT_STACK_ADDR | AT_MEM_PERM_MASK |
| :----: | :--------: | :---------: | :-----------: | :-----------: | :--------------: |
|   0    | 0xFFFF0000 |    0x00     |    0x0000     |  0x00000000   |    0x00000000    |
|   1    | 0x05056718 |    0x7C     |    0x2000     |  0x050BA4A0   |    0x000C0030    |
|   2    | 0xE600F848 |    0x7D     |    0x1000     |  0xE7000000   |    0x00100000    |
|   3    | 0x04015EA4 |    0x7B     |    0x1000     |  0x04028628   |    0x000C0030    |
|   4    | 0x1012E9E8 |    0x6B     |    0x4000     |  0x104B92C8   |    0x00038600    |
|   5    | 0x107F6830 |    0x55     |    0x4000     |  0x1114117C   |    0x001C5870    |
|   6    | 0x11F82D94 |    0x75     |    0x2000     |  0x1214AB4C   |    0x00008180    |
|   7    | 0x123E4174 |    0x50     |    0x4000     |  0x12804498   |    0x00002000    |
|   11   | 0xE22602FC |    0x32     |    0x4000     |  0xE22CB000   |    0x00000000    |
|   9    | 0xE108E930 |    0x32     |    0x1000     |  0xE12E71A4   |    0x00000000    |
|   12   | 0xE3166B34 |    0x32     |    0x4000     |  0xE31AF000   |    0x00000000    |
|   8    | 0xE00D8290 |    0x32     |    0x4000     |  0xE0125390   |    0x00000000    |
|   10   | 0xE500D720 |    0x46     |    0x4000     |  0xE506A900   |    0x00000000    |
|   13   | 0xE40168A4 |    0x4B     |    0x2000     |  0xE415623C   |    0x00000000    |

# 大体のソースコード
```cpp
// IOSU kernel entry-point
// ARM vector table (firmware 5.5.1)
start()  // 0xFFFF0000
{
  // Reset handler
  pc <- sub_FFFF0060

  // Undefined handler
  pc <- loc_812DD6C

  // SWI handler
  pc <- sub_812DD20

  // Prefetch handler
  pc <- sub_812E74C

  // Abort handler
  pc <- sub_812E720

  // NULL
  pc <- loc_FFFF0040

  // IRQ handler
  pc <- loc_FFFF0044

  // FIQ handler
  pc <- loc_FFFF0048
}

// Execution follows into the reset handler:

// Reset handler (firmware 5.5.1)
sub_FFFF0060()
{
  r0 <- 0

  // Invalidate ICache
  MCR p15, 0, R0,c7,c5, 0

  // Invalidate DCache
  MCR p15, 0, R0,c7,c6, 0

  // Read control register
  MRC p15, 0, R0,c1,c0, 0

  // Set replacement strategy to Round-Robin
  r0 <- r0 | 0x1000

  // Enable alignment fault checking
  r0 <- r0 | 0x2

  // Write control register
  MCR p15, 0, R0,c1,c0, 0

  // Clear the IOS-KERNEL stack
  memset_range(stack_start, stack_end, 0, 0x04);

  // Disable boot0 mapping
  r0 <- 0x0D80018C   // HW_SPARE1
  r1 <- 0x00(HW_SPARE1)
  r1 <- r1 | 0x1000
  0x00(HW_SPARE1) <- r1

  // MSR CPSR_c, #0xD3 -> Enter supervisor mode, FIQ/IRQ disabled
  // SP == 0xFFFF0904
  init_svc_stack(0xFFFF0904);

  // MSR CPSR_c, #0xD2 -> Enter IRQ mode, FIQ/IRQ disabled
  // SP == 0xFFFF1104
  init_irq_stack(0xFFFF1104);

  // MSR CPSR_c, #0xD1 -> Enter FIQ mode, FIQ/IRQ disabled
  // SP == 0xFFFF1504
  init_fiq_stack(0xFFFF1504);

  // MSR CPSR_c, #0xD7 -> Enter abort mode, FIQ/IRQ disabled
  // SP == 0xFFFF0D04
  init_abort_stack(0xFFFF0D04);

  // MSR CPSR_c, #0xDB -> Enter undefined mode, FIQ/IRQ disabled
  // SP == 0xFFFF1904
  init_undefined_stack(0xFFFF1904);

  // MSR CPSR_c, #0xDF -> Enter system mode, FIQ/IRQ disabled
  // SP == 0xFFFF1904
  init_user_stack(0xFFFF1904);

  // Jump to MEM0 check
  lr <- pc
  pc <- sub_FFFFDA38

  while(1);
}

// MEM0's integrity is checked before going any further

// Check MEM0 for IOS-KERNEL (firmware 5.5.1)
sub_FFFFDA38()
{
  r1 <- 0x08143008  // IOSU kernel data region
  r3 <- 0xA5A51212

  r2 <- 0x00(0x08143008)

  // Deadlock
  if (0x00(0x08143008) != 0xA5A51212)
  {
     r3 <- 0xDEAD1111
     sp <- 0xDEAD1111
     while(1);
  }

  r12 <- 0xFFFF0500	// IOSU boot heap region
  r2 <- 0x00(0xFFFF0500)

  // Deadlock
  if (0x00(0xFFFF0500) != 0xA5A51212)
  {
     r3 <- 0xDEAD1111
     sp <- 0xDEAD1111
     while(1);
  }

  // Set init magic
  r2 <- 0x5A5AEDED
  0x00(0xFFFF0500) <- 0x5A5AEDED
  0x00(0x08143008) <- 0x5A5AEDED

  // Flush AHB for Starbuck
  ahbMemFlush(0);
  ahb_flush_to(1);

  // Load IOS_KERNEL
  r2 <- sub_8121B18
  sub_8121B18();

  // Deadlock
  r3 <- 0xDEAD2222
  sp <- 0xDEAD2222
  while(1);
}

//And, finally, execution switches over to MEM0 where the IOS-KERNEL module will be running:

// Load IOS-KERNEL (firmware 5.5.1)
sub_8121B18()
{
  // Read LT_DEBUG register
  // and store it's value at 0x08150000
  sub_8120970();

  // Clear LT_DEBUG register
  sub_8120988();

  // Do a bitwise AND with the LT_DEBUG value
  r0 <- 0x80000000
  r0 <- sub_81209B8(0x80000000);

  // If LT_DEBUG is 0x80000000
  // the hardware is using RealView
  if (r0 != 0)
  {
    r4 <- (sp + 0x04)
    r3 <- 0
    0x00(sp) <- 0

    // Wait for user input
    // to start the kernel
    while (r3 != 0x01)
    {
	r0 <- "\n\n\n\n\n\n\n\n\n\n"
	debug_printf("\n\n\n\n\n\n\n\n\n\n");

	r0 <- "Enter '1' to proceed with kernel startup. "
	debug_printf("Enter '1' to proceed with kernel startup. ");

	r0 <- "%d"
        r1 <- sp
	debug_read("%d", sp);

       r3 <- 0x00(sp)
    }
  }

  // Initialize the MMU and map memory regions
  sub_8120C58();

  // Reset GPIOs and IRQs
  sub_8120510();

  // Setup IRQ handlers
  sub_8120488();

  // Clear and set some kernel structures
  sub_812B308();

  // Setup iobuf
  sub_81235E8();

  // Re-map shared_user_ro
  sub_81294AC();

  // Clear IOS_KERNEL module's thread stack and run it
  sub_812CD08();

  return;
}

// この時点で
// IOS-KERNEL モジュールが自分のスレッドを作成する
// すべての IOSU モジュールの起動 / 制御を担当する


```