# スレッド
- IOSU が作成するもので 0xB4 個まで作成できます
- それぞれに対応するスレッドがカーネルの SRAM に保持されています

```cpp
struct
{
  0x00: saved_cpsr
  0x04: saved_r0
  0x08: saved_r1
  0x0C: saved_r2
  0x10: saved_r3
  0x14: saved_r4
  0x18: saved_r5
  0x1C: saved_r6
  0x20: saved_r7
  0x24: saved_r8
  0x28: saved_r9
  0x2C: saved_r10
  0x30: saved_r11
  0x34: saved_r12
  0x38: saved_r13
  0x3C: saved_lr
  0x40: thread_pc
  0x44: thread_queue_next
  0x48: thread_min_priority
  0x4C: thread_max_priority
  0x50: thread_state
  0x54: owner_pid
  0x58: thread_id
  0x5C: flags
  0x60: exit_value
  0x64: join_thread_queue_head
  0x68: current_thread_queue
  0x6C: ?????
  0x70: ?????
  0x74: ?????
  0x78: ?????
  0x7C: ?????
  0x80: ?????
  0x84: ?????
  0x88: ?????
  0x8C: ?????
  0x90: ?????
  0x94: ?????
  0x98: ?????
  0x9C: ?????
  0xA0: ?????
  0xA4: thread_sp
  0xA8: ?????
  0xAC: ?????
  0xB0: sys_stack_addr
  0xB4: user_stack_addr
  0xB8: user_stack_size
  0xBC: ipc_buffer_pool
  0xC0: profiled_count
  0xC4: profiled_time
} thread_t;   // sizeof() = 0xC8
```

# ステート
| value | description |
| :---: | :---------: |
| 0x00  |  Available  |
| 0x01  |    Ready    |
| 0x02  |   Running   |
| 0x03  |   Stopped   |
| 0x04  |   Waiting   |
| 0x05  |    Dead     |
| 0x06  |   Faulted   |
| 0x07  |   Unknown   |