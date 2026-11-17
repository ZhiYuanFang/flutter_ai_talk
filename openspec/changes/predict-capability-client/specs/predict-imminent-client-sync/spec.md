## ADDED Requirements

### Requirement: Imminent pending sync SHALL use silent affinity rail nextAt

When the client builds the body for `PUT /device/api/predict/imminent/pending`, each event’s `nextAt` MUST come from the silent affinity prediction rail, even if the display rail is currently forcing seed-interval times for the same roots. The client MUST NOT substitute display-rail seed nextAt into pending solely because the user is not predict-display-entitled. Existing rules for full-replace sync triggers, empty clear, appointment omission, expect fields, single-flight, and failure cooldown SHALL remain.

imminent pending 的 nextAt MUST 取自静默亲和轨；MUST NOT 因未开通展示强制种子而把种子时刻当作上传权威。

#### Scenario: 未开通上传仍为亲和

- **WHEN** 用户未 entitle，展示卡对根 A 显示种子 nextAt，静默轨对 A 算出不同的亲和 nextAt，且发生合格的本机变更触发 pending 同步
- **THEN** pending 中 A 的 nextAt MUST 为静默亲和值
- **AND** MUST NOT 仅为与卡面一致而上传种子 nextAt
