## Why

智能预测目前只推演「下次何时发生」。家长还需要「这次大概用多久 / 用多少」——预测卡上可见，离线临近推送也能带上。用量与用时量纲不同，须在根事件下分模态维护，再择一展示。

## What Changes

- 在现有 `nextAt` 推演之外，对每个目录根**并行**维护两条量线：
  - **duration**：已结束 `time`（`eventNumber==0`）样本的加权中位用时；
  - **amount**：`number`（`eventNumber>0`）样本的加权中位用量（含单位，可选叶子展示名）。
- 卡片与 pending **只展示/上报有把握的一条**；双线都过门闸时按**最近一次可计量发生**的模态决胜。
- 预测页事件卡在倒计时之外展示预计用量/用时次级文案（统一「约」）。
- `PUT /device/api/predict/imminent/pending` 上报体在 `eventId`/`nextAt`/`title` 之外，附加胜出线的结构化 expect 字段；同步指纹须包含 expect，避免只改量不重传。
- **不**做用量/用时 recall 种子；预约根不预测量；不改间隔算法与门闸。
- 兄弟仓 `go_ai_talk` 同步 change `predict-expect-amount-duration`：Redis/MQ 透传 expect，推送在既有 `{昵称}要{title}了` 上追加后缀。

## Capabilities

### New Capabilities

- `event-expect-prediction`：根下 duration/amount 双线推演、样本门闸、双线决胜、卡片/pending 共用的 expect 展示语义与字段约定。

### Modified Capabilities

- `smart-prediction-page`：热态预测卡 MUST 在存在胜出 expect 时展示次级「预计约…」文案。
- `predict-imminent-client-sync`：pending 全量同步 MUST 携带胜出 expect 结构化字段；指纹 MUST 纳入 expect，避免漏同步。

## Impact

- 代码：`event_next_predictor.dart`（或并列 expect 模块）、`EventNextPrediction`、`smart_prediction_screen` 卡片、`predict_imminent_repository` / `predict_imminent_sync_provider` 指纹与 body。
- API 契约：与 Go `PredictImminentPendingEventItem` 对齐的可选字段（非 BREAKING；旧服务端可忽略）。
- 无新 HTTP 路径；桌面小组件本变更可不带 expect（out of scope）。
- 跨仓：须与 `go_ai_talk` 同名 change 联调后，推送后缀才对用户可见。
