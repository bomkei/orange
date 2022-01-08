# IOS-PAD
ゲームパッド系

## ノード
|                path | description                             |
| ------------------: | :-------------------------------------- |
|          /dev/uhs/1 | USB ホストスタック (内部デバイス)       |
|         /dev/ccr_io | DRC メインサービス                      |
|        /dev/ccr_cdc | DRC RPC (CDC = 対話デバイスクラス)      |
|        /dev/ccr_hid | DRC input                               |
|        /dev/ccr_nfc | DRC NFC リーダー                        |
|        /dev/ccr_uac | DRC マイク                              |
|        /dev/ccr_uvc | DRC カメラ                              |
|       /dev/usb/btrm | BlueTooth (Wii Remote / Pro Controller) |
| /dev/usb/early_btrm | 2 つめの Bluetooth                      |