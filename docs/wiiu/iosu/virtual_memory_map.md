|           vaddr range |           paddr range |   size    | description                       |
| --------------------: | --------------------: | :-------: | :-------------------------------- |
| 0x04000000-0x04030000 | 0x08280000-0x082B0000 |  0x30000  | IOS-CRYPTO                        |
| 0x05000000-0x050C0000 | 0x081C0000-0x08280000 |  0xC0000  | IOS-MCP                           |
| 0x05100000-0x05120000 | 0x13D80000-0x13DA0000 |  0x20000  | IOS-MCP (debug and recovery mode) |
| 0x08120000-0x081C0000 | 0x08120000-0x081C0000 |  0xA0000  | IOS-KERNEL                        |
| 0x10000000-0x10100000 | 0x10000000-0x10100000 | 0x100000  | PRSH/PRST                         |
| 0x10100000-0x104D0000 | 0x10100000-0x104D0000 | 0x3D0000  | IOS-USB                           |
| 0x10700000-0x11C40000 | 0x10700000-0x11C40000 | 0x1540000 | IOS-FS (5.5.1 retail)             |
| 0x10800000-0x11EE0000 | 0x10800000-0x11EE0000 | 0x16E0000 | IOS-FS (5.3.2 debug)              |
| 0x11F00000-0x12160000 | 0x11F00000-0x12160000 | 0x260000  | IOS-PAD                           |
| 0x12300000-0x12890000 | 0x12300000-0x12890000 | 0x590000  | IOS-NET                           |
| 0x1D000000-0x1FB00000 | 0x1D000000-0x1FB00000 | 0x2B00000 | Global heap                       |
| 0x1FB00000-0x1FE00000 | 0x1FB00000-0x1FE00000 | 0x300000  | Global IOB (input/output block)   |
| 0x1FE00000-0x1FE20000 | 0x1FE00000-0x1FE20000 |  0x40000  | IOS-MCP (shared region)           |
| 0x1FE40000-0x20000000 | 0x1FE40000-0x20000000 | 0x1C0000  | IOS-MCP (setup region)            |
| 0x20000000-0x28000000 | 0x20000000-0x28000000 | 0x8000000 | RAMDISK                           |
| 0xE0000000-0xE0270000 | 0x12900000-0x12B70000 | 0x270000  | IOS-ACP                           |
| 0xE1000000-0xE12F0000 | 0x12BC0000-0x12EB0000 | 0x2F0000  | IOS-NSEC                          |
| 0xE2000000-0xE26D0000 | 0x12EC0000-0x13590000 | 0x6D0000  | IOS-NIM-BOSS                      |
| 0xE3000000-0xE3300000 | 0x13640000-0x13940000 | 0x300000  | IOS-FPD                           |
| 0xE4000000-0xE4160000 | 0x13A40000-0x13BA0000 | 0x160000  | IOS-TEST                          |
| 0xE5000000-0xE5070000 | 0x13C00000-0x13C70000 |  0x70000  | IOS-AUXIL                         |
| 0xE6000000-0xE6050000 | 0x13CC0000-0x13D80000 |  0xC0000  | IOS-BSP                           |
| 0xEFF00000-0xEFF08000 | 0xFFF00000-0xFFF08000 |  0x8000   | C2W (cafe2wii) boot heap          |
| 0xFFFF0000-0xFFFFFFFF | 0xFFFF0000-0xFFFFFFFF |  0x10000  | Kernel SRAM / C2W (cafe2wii)      |