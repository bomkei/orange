# ハードウェア
## プロセッサ
CPU: <br>
IBM PowerPC をベースにしたプロセッサ "Espresso" で、周波数は 1243.125 MHz (1.24GHz) 。<br>
消費電力低減と処理速度向上のために、単一チップ上に 3 つのコアを持つ PowerPC アーキテクチャのマイクロプロセッサであることが、IBM と 任天堂から明らかにされている。チップには、CPU キャッシュ用として製造時に eDRAM が埋め込まれている。

GPU: <br>
AMD Radeon で、コードネームは Latte 。<br>
周波数は 549.999 MHz (0.549 GHz) 。

SoC: Starbuck Iteration of Wiis Starlet

## セキュリティープロセッサー
- 名前は Starbuck
- `IOSU` と `boot0` と `boot1` が動く
- `Input/Output Processor` 略して `IOP` とも呼ばれる

## メモリ
MEM1: <br>
32MB

MEM2: <br>
2GB <br>
このうち 1GB は OS が予約しているため ゲームでは使えない。<br>
4つの 4Gbit(512MiB) DDR3-1600 メモリモジュールで構成され、each 3.2GB/s bandwidth for a total of 12.8GB/s

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

