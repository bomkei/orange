# Note
Wii UのCPU等についての情報です

# CPU
- 32bit Bigエンディアン PowerPC (Espresso)
- クロック数が `1243.125 Mhz`
- 3コアある

# GPU
- AMD Radeon (Latte)
- クロック数が `549.999 Mhz`

# メモリ
- 32MB の MEM1
- 2GB の MEM2
  - 1GB は OS が取る
  - だからゲームは 1GB しか使えない

# ストレージ
- 8GB か 32GB の eMMC NAND
- 2つの 512MB NAND (=TSOP48) bankがある
  - よくわかってないけどおそらくバッファリング用途？
    - 要チェックかも
  - 一つは vWii モード用
  - もう一つは Wii U用
- ディスク
  - 4.7 GB/層 → Wii
  - 25 GB/層 → Wii U
  - 基本的にこれだけで良いと思う

# IOSU
- おそらく BIOS をより近代化したようなもの
- と思ったら OS だった CafeOSがこれなのか IOSUの上でCafeOSが動いてるのか 確認が必要かもしれない
- 詳しい情報は [https://wiiubrew.org/wiki/IOSU](IOSU) にある


# セキュリティープロセッサー
- 名前は Starbuck
- `IOSU` と `boot0` と `boot1` が動く
- `Input/Output Processor` 略して `IOP`
