## ADDED Requirements

### Requirement: Catalog SHALL expose trialAvailable per feature
The feature catalog API and client model SHALL expose `trialAvailable` for each commercial feature item. `trialAvailable` MUST be true only when the account has never successfully claimed a free trial for that feature AND the feature is not effectively unlocked (including VIP coverage). 目录项 **必须** 带 `trialAvailable`；已开通或 VIP 覆盖或已 claim 时 **必须** 为 false。

#### Scenario: Unused trial while locked
- **WHEN** 用户从未成功 claim 该功能试用且非 VIP、无有效用户权益
- **THEN** catalog 该项 `trialAvailable` MUST 为 true

#### Scenario: VIP hides trial
- **WHEN** 用户为有效 VIP
- **THEN** 该项 `trialAvailable` MUST 为 false（或客户端按 unlocked 合成后不得展示免费体验）

#### Scenario: After successful claim
- **WHEN** 用户已对该功能成功 claim 试用
- **THEN** `trialAvailable` MUST 为 false

### Requirement: Soft access SHALL allow detail entry without consuming trial
While `trialAvailable` is true (and for care-alert, feeding eligibility is qualified), the client SHALL allow navigation into the feature detail page without writing trial or entitlement rows. Soft access MUST NOT alone mark the trial as used. 试用资格下进详情 **不得** 消耗资格。

#### Scenario: Free-trial CTA enters detail
- **WHEN** 用户在开通中心点击「免费体验」并在确认弹窗选择「体验」且 care 已喂养达标（若适用）
- **THEN** 客户端 MUST 进入对应详情页，且服务端 trial 状态仍为未使用

#### Scenario: Care trial requires feeding qualification
- **WHEN** care 的 `trialAvailable` 为 true 但喂养未达标
- **THEN** 客户端 MUST NOT 展示可点击的「免费体验」进入路径（或点击后提示需先达标），且 MUST NOT claim

### Requirement: First successful generation SHALL claim 24h trial entitlement
On the first successful analysis/prediction persistence for a feature while the request was authorized via unused trial soft access, the server SHALL atomically mark the trial used and grant a user-scoped entitlement of **24 hours** via trial channel. Further successful generations in the soft-access window before claim MUST still be allowed subject to the daily limit; only the first success triggers claim. 试用窗可多次生成；**仅首次成功** claim 并授予 24h。

#### Scenario: First success claims
- **WHEN** soft access 用户首次成功落库 care 或 growth 结果
- **THEN** 服务端 MUST 将 trial 标为已用，MUST 写入 24h 用户权益，随后 catalog `trialAvailable=false` 且 `unlocked` 在有效期内为 true

#### Scenario: Failed generation does not claim
- **WHEN** soft access 用户发起分析但失败未落库
- **THEN** trial MUST 保持未使用

#### Scenario: Second success after claim uses entitlement
- **WHEN** 已 claim 的 24h 内用户再次成功生成
- **THEN** MUST NOT 再次 claim；日额度正常累计

### Requirement: Unlock hub SHALL show free-trial button on the right when eligible
When a catalog item is locked and `trialAvailable` is true (care additionally feeding-qualified), the unlock hub feature card button row SHALL show「免费体验」as the rightmost action. Tapping it MUST open a confirm dialog stating each user has only one free trial; confirming「体验」MUST navigate to the detail page. VIP or unlocked items MUST NOT show the button. 开通页在有资格时 **必须** 在按钮行最右侧展示「免费体验」。

#### Scenario: Show and confirm
- **WHEN** `trialAvailable` 为 true 且功能未开通
- **THEN** 开通卡 MUST 显示最右侧「免费体验」；确认「体验」后 MUST 进入详情

#### Scenario: Hidden when unlocked
- **WHEN** 功能已有效开通或 VIP
- **THEN** MUST NOT 显示「免费体验」
