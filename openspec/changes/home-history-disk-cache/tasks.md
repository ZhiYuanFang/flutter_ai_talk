## 1. 序列化与 Store

- [x] 1.1 `HistoryRecord` 磁盘 JSON：`toJson` / `fromJson`（含 `rawPayload`）
- [x] 1.2 新建 `HomeHistoryStore`：`load(deviceNo)`、`save(deviceNo, items)`；按 deviceNo 分文件
- [x] 1.3 `historySnapshotsEqual(a, b)`：按 id 比较关键字段与顺序

## 2. 主页 cache-first 加载

- [x] 2.1 `_reloadHistoryIfLoggedIn`：先读缓存 setState，再 async `loadHistory`
- [x] 2.2 远端与缓存对比：不等则 save + setState；相等则跳过；失败保留缓存
- [x] 2.3 `deviceNo` 切换时加载对应缓存后再 refresh

## 3. 回写

- [x] 3.1 `watchLatest` 更新 `_items` 后 `unawaited(save)`
- [x] 3.2 `_stopActiveTimer` 成功后 save；delete 推送后 save

## 4. 验证

- [x] 4.1 冷启动：有缓存时首屏立即有列表/今日 chips，无长时间空态
- [x] 4.2 服务端变更后二次进入或 refresh 后 UI 与磁盘更新
- [x] 4.3 断网有缓存：仍展示缓存；无缓存：空列表
- [x] 4.4 `dart analyze` 通过变更文件
