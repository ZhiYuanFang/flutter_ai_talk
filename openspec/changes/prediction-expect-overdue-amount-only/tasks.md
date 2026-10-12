## 1. 卡上 expect 展示门闩

- [x] 1.1 在 `smart_prediction_screen.dart` 计算 `expectLabel`：duration → 一律 null；amount → 仅 `overdue` 时调用 `formatPredictionExpectCardLabel`
- [x] 1.2 确认横/竖屏倒计时上方 expect 共用该门闩；无文案不占位
- [x] 1.3 确认计时中 `activeEtaLabel` 分支未被改动

## 2. 验收

- [ ] 2.1 duration 胜出卡（未超时/已超时）：卡上均无「预计约…」用时
- [ ] 2.2 amount 胜出、倒计时未超时：无用量文案；超时后出现「预计约…」用量且贴倒计时上方
- [ ] 2.3 计时中卡：预计结束行行为与改前一致

## 3. 收尾

- [x] 3.1 不改 pending/引擎 unless 实现中发现必须；无 `app/android/**` 改动
