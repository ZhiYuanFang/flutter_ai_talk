## ADDED Requirements

### Requirement: Grant duration copy SHALL follow pay 30d invite 7d trial 24h
Duration-facing catalog fields and client copy helpers SHALL present payment unlock as 30 days and invite unlock as 7 days for care and growth. Trial grant duration after claim MUST be 24 hours. Ad duration fields MUST NOT drive unlock CTAs. 授予天数文案 **必须** 对齐支付 30 天、邀请 7 天、试用 claim 后 24 小时；**不得** 再用广告天数驱动开通 CTA。

#### Scenario: Pay copy
- **WHEN** 客户端展示 care/growth 支付开通说明
- **THEN** 有效期表述 MUST 为 30 天（或等价「一个月」产品已确认用天数 30）

#### Scenario: Invite copy
- **WHEN** 客户端在仍展示邀请入口时说明邀请授予
- **THEN** MUST 使用 7 天

#### Scenario: Trial confirm copy
- **WHEN** 用户点击「免费体验」确认弹窗
- **THEN** 文案 MUST 表明仅一次机会；成功体验后权益为 24 小时（可在弹窗或成功后提示中体现）
