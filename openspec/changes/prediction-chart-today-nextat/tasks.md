## 1. 取点规则

- [x] 1.1 调整 `dailyPointsNearAnchorTod`（或等价）：过去日仍选 TOD 近 `nextAt` 的 occurrence；今日仅当 `nextAt` 同日本地日时追加 `nextAt`，不用今日已发生点
- [x] 1.2 确认 `nextAt` 在明天及以后时今日无点；同日逾期 `nextAt` 仍画点

## 2. 图表尺度与验收

- [x] 2.1 折线 Y 轴 / 点域包含可能晚于 `now` 的今日 `nextAt`（既有 `anchorM` 纳入 min/max）
- [x] 2.2 手工：nextAt 今天 → 今日点在预测时刻；nextAt 非今天 → 今日无点；过去日行为不变
- [x] 2.3 未改 `app/android/**`；不强制 release APK
