## 1. Range 熔断与失败可观测

- [x] 1.1 在 `PredictionRangeHistoryNotifier` 增加用户显式重试入口：下拉前将 `_consecutiveFailures` 清零，再 `ensureLoaded(force: true)`（或 `resetCircuit` + force）
- [x] 1.2 使该次 force 拉取的成功/失败对调用方可观测（返回 `bool` / 结果类型，避免仅吞错），供 Toast 使用
- [x] 1.3 确认非 force 自动 ensure 在 circuit open 时仍 skip（既有语义不变）

## 2. Home 刷新失败可观测

- [x] 2.1 为预测页下拉路径提供 `refreshFromRemote` 成败信号（返回值或薄封装），在 `tryLoadHistoryPage` 失败等路径可区分失败与早退
- [x] 2.2 复用既有 single-flight（`_refreshFuture`），不新建平行 home 拉取栈

## 3. 预测页 UI 下拉

- [x] 3.1 在 `SmartPredictionScreen.buildCardsBody`（或统一外层）用 `RefreshIndicator` 包裹 list / waterfall / 空态，并设 `AlwaysScrollableScrollPhysics`
- [x] 3.2 `onRefresh`：重置 range 熔断 → 并行或有序等待 home 第 1 页刷新 + range force；任一路失败 `showAppToast` error；不直接调 imminent/ETA PUT；不做底部上拉
- [x] 3.3 竖屏与横屏共用同一刷新路径；指示器在两路结算后结束

## 4. 验收对照

- [x] 4.1 对照本 change specs：空态可拉、一手势两路、失败 Toast、熔断清零、无底部上拉、非 resume 整包
- [x] 4.2 确认未新增裸 `debugPrint`/`print`；无 `app/android/**` 变更故无需 release APK 任务
