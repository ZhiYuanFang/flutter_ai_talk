## 1. 倒计时格式

- [x] 1.1 增加 `HH:MM:SS`（小时可涨、分秒补零）格式化；未超时用 `nextAt - now`，超时固定零 → `00:00:00`

## 2. 网格卡片

- [x] 2.1 `compact` 主区用倒计时替换 `_LookbackChart`；确保 `predictionClockProvider` 驱动刷新
- [x] 2.2 未超时不展示短相对时间行；超时展示 `formatPredictionGridRelative(..., overdue: true)` + 停表
- [x] 2.3 推演关闭 / 无预测时网格行为与现网一致（置灰、无倒计时主区）

## 3. 验收

- [x] 3.1 网格：未超时仅倒计时递减；超时 `00:00:00` +「超时 …」
- [x] 3.2 列表：仍为近 7 日折线与原相对时间
