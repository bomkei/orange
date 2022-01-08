# ヒープ
- IOSU が作成するもので 0x30 個まで管理できます
- 対応する記述子がカーネルの BSS セクションに保持されています

```cpp
// Heap descriptor
struct
{
  0x00: base
  0x04: owner_pid
  0x08: size
  0x0C: first_free
  0x10: error_count_out_of_memory
  0x14: error_count_free_block_not_in_heap
  0x18: error_count_expand_invalid_block
  0x1C: error_count_corrupted_block
  0x20: flags
  0x24: total_allocated_size
  0x28: largest_allocated_size
  0x2C: total_allocation_count
  0x30: total_freed_count
  0x34: error_count_free_unallocated_block
  0x38: error_count_alloc_invalid_heap
  0x3C: heap_id
} heap_descriptor_t;   // sizeof() = 0x40
```

## 特殊なヒープ ID
| Heap ID |              Purpose              |
| :-----: | :-------------------------------: |
| 0x0001  |            Shared heap            |
| 0xCAFE  | Local process heap for active PID |
| 0xCAFF  | Cross process heap for active PID |

# ヘッダー
```cpp
// Heap chunk header
struct
{
  0x00: magic
  0x04: size
  0x08: back
  0x0C: next
} heap_chunk_header_t;   // sizeof() = 0x10
```
## agic
|   value    |            meaning            |
| :--------: | :---------------------------: |
| 0xBABE0000 |         Chunk is free         |
| 0xBABE0001 |        Chunks is used         |
| 0xBABE0002 | Chunk is inner chunk and used |