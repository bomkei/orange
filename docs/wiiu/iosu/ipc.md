# IPC
- プロセス間通信です
- IPC インターフェイスを使って IOSU ドライバを呼べます
- これは内部的に IOSU と同じ呼び出しインターフェイスを使っています
- カーネルにはどの Code OS のプロセスが呼び出ししたかの情報があるため、アプリ単位で権限管理ができます

# リクエスト構造体
- 0x48 バイトで 0x20 単位でアラインメントされています

| Value |                        Description                         |
| :---: | :--------------------------------------------------------: |
| 0x00  |                            CMD                             |
| 0x04  |                      Reply to client                       |
| 0x08  |                         Client FD                          |
| 0x0C  |                      Flags (always 0)                      |
| 0x10  |       Client CPU (0=ARM internal, 1-3=PPC cores 0-2)       |
| 0x14  | Client PID (PFID in older versions, RAMPID more recently?) |
| 0x18  |             Client group ID (Title ID, upper)              |
| 0x1C  |             Client group ID (Title ID, lower)              |
| 0x20  |              Server handle (written by IOSU)               |
| 0x24  |                            Arg0                            |
| 0x28  |                            Arg1                            |
| 0x2C  |                            Arg2                            |
| 0x30  |                            Arg3                            |
| 0x34  |                            Arg4                            |
| 0x38  |                       CMD (previous)                       |
| 0x3C  |                    Client FD (previous)                    |
| 0x40  |       Virt0 (PPC virtual addresses to be translated)       |
| 0x44  |       Virt1 (PPC virtual addresses to be translated)       |

## コマンド一覧
| Value |           Description           |
| :---: | :-----------------------------: |
| 0x00  |       IOS_COMMAND_INVALID       |
| 0x01  |            IOS_OPEN             |
| 0x02  |            IOS_CLOSE            |
| 0x03  |            IOS_READ             |
| 0x04  |            IOS_WRITE            |
| 0x05  |            IOS_SEEK             |
| 0x06  |            IOS_IOCTL            |
| 0x07  |           IOS_IOCTLV            |
| 0x08  |  IOS_REPLY (internal to IOSU)   |
| 0x09  | IOS_IPC_MSG0 (internal to IOSU) |
| 0x0A  | IOS_IPC_MSG1 (internal to IOSU) |
| 0x0B  | IOS_IPC_MSG2 (internal to IOSU) |
| 0x0C  | IOS_SUSPEND (internal to IOSU)  |
| 0x0D  |  IOS_RESUME (internal to IOSU)  |
| 0x0E  |  IOS_SVCMSG (internal to IOSU)  |

## 引数
|  CMD   | ClientFD |  Arg0  |   Arg1    |    Arg2    |  Arg3  |  Arg4  |
| :----: | :------: | :----: | :-------: | :--------: | :----: | :----: |
|  Open  |    0     |  name  | name_size |    mode    |  後述  |   <    |
| Close  |  not 0   |   -    |     -     |     -      |   -    |   -    |
|  Read  |  not 0   | outPtr |  outLen   |     -      |   -    |   -    |
| Write  |  not 0   | inPtr  |   inLen   |     -      |   -    |   -    |
|  Seek  |  not 0   | where  |  whence   |     -      |   -    |   -    |
| IOctl  |  not 0   |  cmd   |   inPtr   |   inLen    | outPtr | outLen |
| IOctlv |  not 0   |  cmd   | readCount | writeCount | vector |   -    |

### Open の Arg3,4 について
u64 permissions_bitmask for the target IOSU process, loaded by the target IOSU process during fd init. With PPC this originates from the cos.xml of the source process.
- Arg3,4 は 2 つで 1 つの引数です(64 ビット)
- 対象の IOSU プロセスに対するパーミッションビットマスクです
  - fd init の際にロードされます
  - PPC ではソースプロセスの cos.xml から生成されます

## エラーコード一覧
|   Value    | Name                       |
| :--------: | :------------------------- |
| 0x00000000 | IOS_ERROR_OK               |
| 0xFFFFFFFF | IOS_ERROR_ACCESS           |
| 0xFFFFFFFE | IOS_ERROR_EXISTS           |
| 0xFFFFFFFD | IOS_ERROR_INTR             |
| 0xFFFFFFFC | IOS_ERROR_INVALID          |
| 0xFFFFFFFB | IOS_ERROR_MAX              |
| 0xFFFFFFFA | IOS_ERROR_NOEXISTS         |
| 0xFFFFFFF9 | IOS_ERROR_QEMPTY           |
| 0xFFFFFFF8 | IOS_ERROR_QFULL            |
| 0xFFFFFFF7 | IOS_ERROR_UNKNOWN          |
| 0xFFFFFFF6 | IOS_ERROR_NOTREADY         |
| 0xFFFFFFF5 | IOS_ERROR_ECC              |
| 0xFFFFFFF4 | IOS_ERROR_ECC_CRIT         |
| 0xFFFFFFF3 | IOS_ERROR_BADBLOCK         |
| 0xFFFFFFF2 | IOS_ERROR_INVALID_OBJTYPE  |
| 0xFFFFFFF1 | IOS_ERROR_INVALID_RNG      |
| 0xFFFFFFF0 | IOS_ERROR_INVALID_FLAG     |
| 0xFFFFFFEF | IOS_ERROR_INVALID_FORMAT   |
| 0xFFFFFFEE | IOS_ERROR_INVALID_VERSION  |
| 0xFFFFFFED | IOS_ERROR_INVALID_SIGNER   |
| 0xFFFFFFEC | IOS_ERROR_FAIL_CHECKVALUE  |
| 0xFFFFFFEB | IOS_ERROR_FAIL_INTERNAL    |
| 0xFFFFFFEA | IOS_ERROR_FAIL_ALLOC       |
| 0xFFFFFFE9 | IOS_ERROR_INVALID_SIZE     |
| 0xFFFFFFE8 | IOS_ERROR_NO_LINK          |
| 0xFFFFFFE7 | IOS_ERROR_AN_FAILED        |
| 0xFFFFFFE6 | IOS_ERROR_MAX_SEM_COUNT    |
| 0xFFFFFFE5 | IOS_ERROR_SEM_UNAVAILABLE  |
| 0xFFFFFFE4 | IOS_ERROR_INVALID_HANDLE   |
| 0xFFFFFFE3 | IOS_ERROR_INVALID_ARG      |
| 0xFFFFFFE2 | IOS_ERROR_NO_RESOURCE      |
| 0xFFFFFFE1 | IOS_ERROR_BUSY             |
| 0xFFFFFFE0 | IOS_ERROR_TIMEOUT          |
| 0xFFFFFFDF | IOS_ERROR_ALIGNMENT        |
| 0xFFFFFFDE | IOS_ERROR_BSP              |
| 0xFFFFFFDD | IOS_ERROR_DATA_PENDING     |
| 0xFFFFFFDC | IOS_ERROR_EXPIRED          |
| 0xFFFFFFDB | IOS_ERROR_NO_R_ACCESS      |
| 0xFFFFFFDA | IOS_ERROR_NO_W_ACCESS      |
| 0xFFFFFFD9 | IOS_ERROR_NO_RW_ACCESS     |
| 0xFFFFFFD8 | IOS_ERROR_CLIENT_TXN_LIMIT |
| 0xFFFFFFD7 | IOS_ERROR_STALE_HANDLE     |
| 0xFFFFFFD6 | IOS_ERROR_UNKNOWN_VALUE    |