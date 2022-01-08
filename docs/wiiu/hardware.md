# ハードウェア
## プロセッサ
CPU: Espresso (PowerPC ベース) @1243.125 Mhz (=1.24Ghz)
- 単一チップ状に 3 つのコアを持つ PowerPC アーキテクチャのマイクロプロセッサ
  - IBM と任天堂より
- チップに CPU キャッシュ用として製造時に eDRAM が埋め込まれている。

GPU: AMD Radeon で、コードネームは Latte 。<br>
周波数は 549.999 MHz (0.549 GHz) 。

SoC: Starbuck Iteration of Wiis Starlet

## セキュリティープロセッサー
- 名前は Starbuck
- `IOSU` と `boot0` と `boot1` が動く
- `Input/Output Processor` 略して `IOP` とも呼ばれる

## メモリ
MEM1: 32MB  
MEM2: 2GB
- 1GB は OS が予約
  - = その分はゲームでは使えない
- 4つの 4Gbit (=512Mib) DDR3-1600 メモリモジュールで構成されている
- それぞれ 3.2GB/s
  - = 合計 12.8GB/s

## ストレージ
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

