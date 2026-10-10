## 1. Store 与 Provider

- [x] 1.1 新增 `EventLastAtStore`（SharedPreferences `event_last_at_v1_<deviceNo>`，根 eventId → ISO8601），与 `PredictionRecallSeedStore` 隔离
- [x] 1.2 新增 Riverpod Notifier：按当前 `deviceNo` 加载/暴露 `Map<String, DateTime>`；提供 `observe(root, at)`（max 写盘）与 `invalidateTip(root, deletedAt, visibleLatest)`（删 tip 重算/清键）
- [x] 1.3 在 wipe / 切换宝宝路径清理或 reload 对应 device 缓存，避免串读

## 2. 写入点

- [x] 2.1 home / prediction-range 真历史合并入内存时，对每条可解析发生时刻的非种子记录 `observe` 到目录根
- [x] 2.2 新增/改时间成功入列路径 `observe`
- [x] 2.3 历史 WS 入列/更新路径 `observe`（若与 2.1 同源可复用单一 hook）
- [x] 2.4 删除成功：若可能打到 tip 则 `invalidateTip`（窗内仍有则写回最新，否则清键）

## 3. 读兜底与推演

- [x] 3.1 `buildSmartPredictionRows`（或紧邻层）：`lastAt = windowLatest ?? cache[root]`；组行 watch 缓存 map
- [x] 3.2 预测锚点与行同源可用缓存；间隔样本仍只用窗口真记录；不得用 `PredictionRecallSeed.lastAt` 顶替
- [x] 3.3 「上一次」可点编辑仍仅在窗内能解析真 `HistoryRecord` 时开放

## 4. 验收

- [x] 4.1 手工：某根仅窗外有历史（或杀进程后窗口暂无该根）→ 卡显示缓存「上一次」；开推演不误出「补充上一次」
- [x] 4.2 手工：删 tip 且窗内无该根 →「暂无」且种子按既有规则清除；窗内仍有更早记录 → 文案跟剩余最新
- [x] 4.3 对照 `event-last-at-cache` / `event-interval-prediction` / `smart-prediction-page` delta 勾验收
