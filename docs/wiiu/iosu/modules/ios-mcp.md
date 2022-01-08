# IOS-MCP
主にタイトルを管理します

## ワームブートの仕事
- MEM1 をクリア
- NAND から fw.img を取り込む
- Ancast ヘッダを検証
- Starbuck ancast key を使って復号化
- execute_privileged でメモリ保護を無効化して ELF ローダへ飛ぶ
- (俗に言う warm boot)

## ノード
|              path | description                                      |
| ----------------: | :----------------------------------------------- |
|          /dev/mcp | タイトル起動(Wii U からの ES もカプセル化します) |
| /dev/mcp_recovery | `/dev/mcp` のリカバリモード                      |
|     /dev/volflush | Volume のキャッシュをフラッシュするサービスです  |
|           /dev/pm | 電源管理                                         |
|       /dev/syslog | システムログ                                     |
|   /dev/usb_syslog | USB システムログ                                 |
|    /dev/dk_syslog | DevKit system logging                            |
|      /dev/ppc_app | PowerPC アプリケーションサービス                 |
|   /dev/ppc_kernel | PowerPC カーネルサービス                         |
