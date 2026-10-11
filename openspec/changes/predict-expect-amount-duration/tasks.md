## 1. 模型与双线推演

- [x] 1.1 扩展 `EventNextPrediction`（或并列结构）承载胜出 expect：`expectKind` / `expectDurationSec` / `expectAmount` / `expectUnit` / `expectLeafTitle`
- [x] 1.2 在预测管道中按根抽取 duration / amount 加权样本（复用桶权重与半衰期；≥2 样本门闸；禁种子；预约根跳过）
- [x] 1.3 实现双线决胜：仅一条有把握取之；双线有把握取最近可计量模态；该线无把握则回退；皆无则省略
- [x] 1.4 提供「预计约…」格式化（时长对齐今日汇总；用量统一「约」，不用「需要」）

## 2. 预测页卡片

- [x] 2.1 热态卡在有胜出 expect 时展示次级文案；无 expect 不占位
- [x] 2.2 横屏紧凑卡可省略叶子名，保留时长或数量+单位

## 3. Pending 同步

- [x] 3.1 `PredictImminentRepository.syncPending` 序列化胜出 expect 可选字段（与 Go 契约对齐）
- [x] 3.2 `predict_imminent_sync_provider` 指纹纳入 expect，确保仅量变化也会 PUT
- [x] 3.3 对照兄弟仓 `go_ai_talk` 同名 change 字段名做一次联调核对（文档/抓包）

## 4. 验收

- [ ] 4.1 手工：睡眠类 ≥2 次已结束计时 → 卡上见「预计约…时长」；本机变更后 pending 含 `expectKind=duration`
- [ ] 4.2 手工：喂养配方奶 ≥2 次 number → 卡上见「预计约…毫升」；pending 含 amount/unit/叶子名
- [ ] 4.3 手工：双线都够样本时，最近一次可计量模态决定卡片与 pending 的 kind
