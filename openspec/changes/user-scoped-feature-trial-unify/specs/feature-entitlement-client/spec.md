## ADDED Requirements

### Requirement: Client entitlement helpers SHALL prefer user-scoped catalog fields
Client feature entitlement helpers SHALL treat care-alert and growth as unlocked from catalog `unlocked` / VIP synthesis and MUST consume `trialAvailable` and `inviteAvailable` for CTA visibility. They MUST NOT depend on device-scoped care entitlement rows or `prediction_unlock.allowedCount` for commercial gating. 客户端权益辅助 **必须** 以用户维 catalog 字段为准，**不得** 再依赖宝宝维 care 权益或预测槽位数做商业门闸。

#### Scenario: Trial CTA uses trialAvailable
- **WHEN** catalog 返回 `trialAvailable=true` 且未 unlocked
- **THEN** 开通相关 UI MUST 可展示免费体验入口（care 另受喂养达标约束）

#### Scenario: Slot helpers removed or no-op
- **WHEN** 业务代码需要判断预测是否「槽位已满」
- **THEN** 商业槽位判断 MUST 已删除或恒为不受限（无槽位门闸）
