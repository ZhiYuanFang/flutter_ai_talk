## ADDED Requirements

### Requirement: Feature catalog SHALL expose invite and ad grant duration days

The App feature catalog API SHALL include per-item grant duration fields `inviteDurationDays` and `adDurationDays` (non-negative integers; `0` means permanent). These values MUST come from server-side feature definition configuration for invite-code and ad channels respectively, and MUST NOT be derived from payment SKU `products[].durationDays`. The Flutter client MUST parse these fields on each catalog item and MUST use `inviteDurationDays` when composing invite-code unlock copy for a feature. 服务端 catalog **必须** 下发 `inviteDurationDays` / `adDurationDays`（0=永久），来源为功能定义上的邀请/广告授予配置，**不得**用付费 SKU 天数冒充；客户端 **必须** 解析并在邀请开通文案中使用邀请授予天数。

#### Scenario: Catalog item includes grant days

- **WHEN** 客户端成功拉取 `GET /cash/app/api/feature/catalog`
- **THEN** 每个目录项 MUST 包含 `inviteDurationDays` 与 `adDurationDays`（整数，≥0）
- **AND** 两字段 MUST NOT 被假定等于任意 `products[].durationDays`

#### Scenario: Invite unlock copy uses inviteDurationDays

- **WHEN** UI 需要展示「邀请码可兑换多久」类文案且该项 `inviteDurationDays` 已知
- **THEN** 客户端 MUST 使用该项的 `inviteDurationDays`（经既有天数字符串规则，含 0→永久）
- **AND** MUST NOT 使用 `products[0].durationDays` 作为邀请授予天数

#### Scenario: Missing grant fields degrade safely

- **WHEN** 某目录项缺少 `inviteDurationDays`（旧服务端或解析失败）
- **THEN** 客户端 MUST NOT 用付费 SKU 天数填补
- **AND** 邀请开通正文 MUST 弱化或省略具体天数，仍允许打开邀请码输入与开通流程

#### Scenario: Unlock hub invite dialog shows grant days

- **WHEN** 用户在开通中心对非预测功能打开邀请码弹框且 `inviteDurationDays` 已知
- **THEN** 弹框正文 MUST 展示该邀请授予有效期（含 0→永久）
- **AND** 预测功能正文 MUST 仍为永久 +1 槽位语义

#### Scenario: Unlock hub ad dialog shows grant days

- **WHEN** 用户在开通中心对非预测功能打开看广告确认框且 `adDurationDays` 已知
- **THEN** 确认文案 MUST 展示该广告授予有效期
- **AND** MUST NOT 使用付费 `products[].durationDays` 冒充
