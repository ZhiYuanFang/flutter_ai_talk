## 1. 主页历史 Provider 监听

- [x] 1.1 在 `HomeHistoryNotifier` 增加 `onDeviceNoChanged`（epoch bump、清内存缓存、bootstrap single-flight）
- [x] 1.2 在 `homeHistoryProvider` 工厂内 `ref.listen(deviceNoNotifierProvider)`：已登录且 `prevDn != nextDn` 且 next 非空时调用

## 2. 预测 range 与绑定页双保险

- [x] 2.1 扩展 `predictionRangeHistoryProvider` 的 deviceNo listen：`prevDn != nextDn` 且 next 非空时 `ensureLoaded(force: true)`
- [x] 2.2 `baby_bind_screen` 在 `_bind` / `_create` 成功路径 `unawaited` 调度 `homeHistory.bootstrap()` 与 `predictionRange.ensureLoaded(force: true)`

## 3. 验收

- [ ] 3.1 真机：预测页门闸 → 绑定已有宝宝 → 返回后主页历史非空（或正确空态且可添加）；喂养页切过去数据一致
- [ ] 3.2 真机：若可测换绑 A→B，列表变为 B 的数据，无 A 残留
- [x] 3.3 `flutter analyze` 改动文件通过
