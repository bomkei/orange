# IOS-MCP
USB コントローラーとデバイス

## ノード
|          path | description                     |
| ------------: | :------------------------------ |
| /dev/usbproc1 | USB 内部プロセス                |
| /dev/usbproc2 | `/dev/usbproc1` の予備          |
|    /dev/uhs/0 | USB ホストスタック (外部ポート) |
|  /dev/usb_cdc | USB 対話用デバイスクラス        |
|  /dev/usb_hid | USB HID                         |
|  /dev/usb_uac | USB Audio                       |
| /dev/usb_midi | USB MIDI                        |