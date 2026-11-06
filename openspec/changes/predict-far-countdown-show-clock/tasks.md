## 1. 时刻拆分与远距门闩

- [x] 1.1 将预估时刻拆为 `datePrefix`（可空）+ `hm`；`formatPredictionCountdownHms` / 调用方在「时刻态」使用拆分结果
- [x] 1.2 时刻态条件：`overdue || (nextAt − now > 6h)`；时刻态大数字只显示预估时刻，否则 `H:MM:SS`

## 2. UI

- [x] 2.1 时刻态标题「预计{titleName}时刻」；倒计时态保持「距离下次{titleName}倒计时」
- [x] 2.2 有日期前缀时前缀字号明显小于 `HH:mm`（Row/RichText）；今日无前缀

## 3. 验收

- [x] 3.1 手工：&gt;6h 只见时刻+预计标题；≤6h 倒计时；跨日日期更小；不新建 `**/test/**`（待真机确认）
