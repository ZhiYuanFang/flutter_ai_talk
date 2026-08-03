## 1. 模型与持久化

- [x] 1.1 `_ChatItem` 增加可空 `at`；用户发送 / 助手创建 / tip 注入打点
- [x] 1.2 `PangbaoClinicTurn`（含 tip）序列化/反序列化 `at`；hydrate 写回气泡

## 2. UI

- [x] 2.1 格式化：同日 `HH:mm`，跨日带日期；divider 不显示
- [x] 2.2 `_buildItem` 气泡上方小字样式

## 3. 验收与收尾

- [ ] 3.1 手工：发消息与 tip 注入见时间；杀进程恢复；旧数据无 at 不崩
- [x] 3.2 未改 `app/android/**` 则无需 release APK
