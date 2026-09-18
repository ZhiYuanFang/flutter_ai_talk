## 1. Sync 入口改造

- [x] 1.1 将 `predict_imminent_sync_provider.dart` 改为导出显式 `requestPredictImminentPendingSync`（保留 single-flight / 指纹 / 熔断 / `AppDebugLog.predictImminent`）
- [x] 1.2 移除对 `smartPredictionsProvider`、session、deviceNo 及首次订阅的盲听自动 sync；清理主壳仅为激活 listen 的 `watch`
- [x] 1.3 在 request 内先 `ref.read(smartPredictionsProvider)` 再 PUT，保证使用已重算列表

## 2. 本机写路径挂点

- [x] 2.1 本机加餐/乐观写入路径（如 `insertOptimistic` 或 `event_add_actions` 写完后）调用 request
- [x] 2.2 本机结束计时（`replaceRecordImmediate`）与本机编辑/删除喂养记录后调用 request
- [x] 2.3 `PredictionRecallSeedsNotifier.upsertSeed`（及会改变有效间隔的 clear）成功后调用 request
- [x] 2.4 确认 `history_ws_home_bridge`、`bootstrap`、`ensureLoaded(force)` / resume 包 **不** 调用 request

## 3. 校验

- [x] 3.1 `dart analyze` 相关改动文件无新增 error
- [x] 3.2 对照 spec：本机记一笔有 pending PUT；resume/拉 range 无；他端 WS 入账无
