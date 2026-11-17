## ADDED Requirements

### Requirement: Client SHALL model predict capability basic and pro catalog ids

The client SHALL recognize feature ids `predict_capability_basic` and `predict_capability_pro` from `GET /cash/app/api/feature/catalog` alongside existing commercial features. Helpers MUST expose time-valid unlock for each id from catalog `unlocked` + `expiresAt` without inventing local prices. The client MUST NOT revive `prediction_unlock` slot gating for these capabilities.

客户端 MUST 识别预测两档 catalog id；MUST NOT 复活 prediction_unlock 槽位门闸。

#### Scenario: catalog 含两档

- **WHEN** catalog 返回 basic 与 pro 两项
- **THEN** 客户端 MUST 可按 featureId 读取 unlocked / expiresAt / trialAvailable / products

### Requirement: Client SHALL support explicit feature trial start API

The client SHALL provide a repository method to `POST /cash/app/api/feature/trial/start` with body `{ featureId }` under the logged-in bound session (deviceNo via gateway headers only). Success MUST be followed by catalog refresh on call sites that claim trial. This path is for predict capability click-trial; care/growth MUST remain on soft access + first-success claim.

客户端 MUST 实现 trial/start；成功后调用方 MUST 刷新 catalog；care/growth MUST NOT 改走本接口改语义。

#### Scenario: basic 点试用

- **WHEN** 客户端对 `predict_capability_basic` 调用 trial/start 且服务端成功
- **THEN** 随后 catalog 刷新 MUST 反映 unlocked 与试用消耗（trialAvailable=false）

### Requirement: Predict display entitlement helper SHALL OR VIP with basic and pro

In addition to catalog `item.unlocked || isVip` used for generic hub chrome, the client SHALL expose a predict-display entitlement helper that is true when basic time-valid OR pro time-valid OR settled isVip. Side-effect paths that branch on this helper MUST await shared VIP settlement before treating isVip as false.

预测展示覆盖 helper MUST = basic∨pro∨VIP；副作用路径 MUST await VIP settle。

#### Scenario: VIP settle 后覆盖

- **WHEN** basic/pro unlocked=false 且 VIP settle 为 true
- **THEN** predict display entitlement MUST 为 true
