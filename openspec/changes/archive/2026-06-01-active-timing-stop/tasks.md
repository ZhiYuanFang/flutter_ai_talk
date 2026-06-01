## 1. 进行中计时工具

- [x] 1.1 在 `history_line_format.dart` 新增 `isActiveTimingRecord`、`activeTimingStartAt`、`formatActiveTimerElapsed`（<1h `MM:SS`，≥1h `HH:MM:SS`）
- [x] 1.2 补充/调整 `historyHomeRowDisplay`：进行中 trailing 改为占位或由 tile 接管动态尾注（避免与静态「开始计时」冲突）

## 2. 主页历史行

- [x] 2.1 `HomeHistoryTimelineTile`：进行中尾注 `Row`（时长 + 「停止」），支持 `onStop`；停止点击不触发 `onTap`
- [x] 2.2 `HomeHistoryScroll`：传入 `tickNow`、`onStopActiveTimer(record)`
- [x] 2.3 `HomeScreen`：扫描进行中、`Timer.periodic(1s)`、实现 `_stopActiveTimer`（`updateHistoryRecord` + 防连点 + 乐观/SSE 刷新）

## 3. 详情预览

- [x] 3.1 `HistoryDetailScreen` 预览：进行中展示「已计时长」（每秒刷新）+ 「停止」；停止成功后刷新记录或 `pop(true)`
- [x] 3.2 详情页 `Timer` 生命周期与 `dispose` 清理

## 4. 验证

- [x] 4.1 手测：单条进行中 → 时长 `05:23` 跳动 → 直接停止 → 行变为已结束用时
- [x] 4.2 手测：两条同时进行中 → 各行独立时长与停止；满 1 小时显示 `01:12:05`（可改系统时间或 mock 验证格式分支）
- [x] 4.3 手测：详情预览停止与主页列表状态一致
