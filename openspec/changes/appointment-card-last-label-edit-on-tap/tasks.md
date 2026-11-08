## 1. 文案

- [x] 1.1 `formatPredictionLastOccurrenceLabel`（或等价）：支持预约省略「上一次{事件名}」前缀，输出 `{相对时间}[ · remark]`
- [x] 1.2 瀑布/compact 预约卡传入短格式；非预约保持原前缀

## 2. 点按再拉编辑

- [x] 2.1 预约卡上次行：有 `displayLastAt` 即可点（不依赖近窗 `HistoryRecord`）
- [x] 2.2 点按 single-flight：不限窗 filter（根及子、`limit=1`）→ 成功开 `showHomeHistoryEditSheet`；空/失败 toast，不开空 sheet
- [x] 2.3 非预约 `editLastTapFor` 仍仅近窗可解析时开放

## 3. 验收

- [x] 3.1 预约卡：无「上一次{名}」；有时间/备注；点按可编辑（含久远上次）；失败有提示
- [x] 3.2 非预约卡：文案与「仅缓存不编辑」行为不变
