## 1. 折线展示

- [x] 1.1 `_LookbackChart`：Y 轴时刻刻度改为 ≤5（由 minY/maxY 推导 step，网格可共用）
- [x] 1.2 双 `LineChartBarData`：过去点实线；`[lastPast, todayNextAt]` 虚线；无今日点则仅实线
- [x] 1.3 `lineTouchData`：触点上方浮层展示该点 `HH:mm`

## 2. 验收

- [x] 2.1 手工：刻度 ≤5；触点浮层；有今日 nextAt 时末段虚线、历史实线
- [x] 2.2 未改 `app/android/**`；不强制 release APK
