## 1. 忽略 session_sync 展示

- [x] 1.1 `session_sync` 帧：不调用 `_applySessionSync`（可打日志后 return）
- [x] 1.2 删除或停用 `_applySessionSync` / 仅服务于 sync 的 divider 合并路径，避免误用

## 2. 本地路径确认

- [x] 2.1 确认 hydrate、发送/流式 persist、tip 注入、清理记录仍工作
- [ ] 2.2 手工：重连后列表不被服务端 turns 重排；本地 tip/时间仍在

## 3. 收尾

- [x] 3.1 未改 `app/android/**` 则无需 release APK
