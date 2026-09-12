## MODIFIED Requirements

### Requirement: Per-card interval recall SHALL apply when hot state lacks prediction but has lastAt

When the smart prediction page renders a real (non-demo-skeleton) prediction event card for a root event whose forecast is enabled, whose **real** feeding history provides a non-null `lastAt`, and whose local predictor returns no `prediction` (sample gate unmet and no usable seed interval yet), the card MUST show a full-width event-accent heartbeat `FilledButton` inviting the user to supply a typical interval. Activating it MUST open a glass bottom sheet with only the「大概多久一次」wheel picker (minimum 15 minutes). On confirm, the client MUST upsert a `PredictionRecallSeed` whose `interval` is the chosen duration and whose persisted `lastAt` MAY snapshot the current real lastAt for storage compatibility, MUST NOT write feeding history, MUST NOT issue care-alert or tip HTTP, and MUST NOT rely on synthesizing pseudo `HistoryRecord` occurrence points for the prediction pipeline. After upsert, the unified predictor MUST produce `nextAt = realLastAt + seed.interval` on the next rows rebuild. When real `lastAt` is null, forecast is disabled, a prediction already exists from the median path or an existing seed interval, or the row is a demo skeleton, the client MUST NOT show this interval control. The client MUST NOT introduce an interval-only draft that predicts without a real `lastAt`.

热态预测卡在推演开启、**真喂养**有非空 `lastAt`、本地尚无 prediction（样本未达标且尚无可用种子间隔）时，MUST 展示心跳「补充大概多久一次」；确认后 MUST upsert 以所选时间为 `interval` 的 `PredictionRecallSeed`（持久化可快照真 `lastAt`），MUST NOT 写喂养历史、MUST NOT 打留意/tip HTTP，MUST NOT 靠合成伪历史喂入推演；其后统一公式 MUST 为 `nextAt = 真 lastAt + seed.interval`。无真 `lastAt`、推演关、已有预测或骨架时 MUST NOT 展示该控件；MUST NOT 在无真 `lastAt` 时仅靠草稿间隔产出预测。

#### Scenario: 有真 lastAt 仅选间隔

- **WHEN** 用户查看某根事件卡且 `forecastEnabled == true`、`prediction == null`、真 `lastAt != null`
- **THEN** 卡片 MUST 展示全宽心跳「补充大概多久一次」
- **AND** 点击 MUST 打开仅间隔滚轮 Sheet
- **AND** MUST NOT 要求选择上次发生时间

#### Scenario: 确认后种子作间隔旁路生效

- **WHEN** 用户在 Sheet 中选择有效间隔并确认
- **THEN** 客户端 MUST upsert 该根的 `PredictionRecallSeed`（含 `interval`）
- **AND** 该卡 MUST 在刷新后以 `真 lastAt + seed.interval` 展示 countdown / nextAt
- **AND** MUST NOT 经喂养 POST 写入历史
- **AND** MUST NOT 将种子合成伪 `HistoryRecord` 并入预测历史列表

#### Scenario: 无真 lastAt 不展示间隔

- **WHEN** 热态某根卡 `forecastEnabled == true`、`prediction == null`、真 `lastAt == null`
- **THEN** 「补充大概多久一次」MUST NOT 展示

#### Scenario: demo 骨架不展示

- **WHEN** 预测页处于 demo 骨架行
- **THEN** per-card 间隔控件 MUST NOT 展示

#### Scenario: 关推演不展示间隔

- **WHEN** 热态某根卡 `forecastEnabled == false`
- **THEN** per-card 间隔控件 MUST NOT 展示
