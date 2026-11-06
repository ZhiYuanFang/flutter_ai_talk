## 1. 逾期大数字

- [x] 1.1 改 `formatPredictionCountdownHms`（或抽共享 helper）：`overdue` 时输出预估本地时刻；今天仅 `HH:mm`（无「今天」）；昨天「昨天 HH:mm」；更早「M月D日 HH:mm」；未逾期仍为 `H:MM:SS`

## 2. 标题

- [x] 2.1 `_buildAppointmentAwareCountdown`：逾期用「预计{titleName}时刻」，未逾期保持「距离下次{titleName}倒计时」；调用方传入 overdue

## 3. 验收

- [x] 3.1 真机/手工：今日逾期见 `HH:mm` + 新标题；未逾期倒计时与旧标题不变；不新建 `**/test/**`（待真机确认）
