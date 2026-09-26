## MODIFIED Requirements

### Requirement: Soft access SHALL allow detail entry without consuming trial
While `trialAvailable` is true (and for care-alert, feeding eligibility is qualified), the client SHALL allow navigation into the feature detail page without writing trial or entitlement rows. Soft access MUST NOT alone mark the trial as used. Care soft access MUST NOT be offered or entered when feeding eligibility is unqualified. 试用资格下进详情 **不得** 消耗资格；care **必须** 喂养达标才可 soft access。

#### Scenario: Free-trial CTA enters detail
- **WHEN** 用户在开通中心点击「免费体验」并在确认弹窗选择「体验」且 care 已喂养达标（若适用）
- **THEN** 客户端 MUST 进入对应详情页，且服务端 trial 状态仍为未使用

#### Scenario: Care trial requires feeding qualification
- **WHEN** care 的 `trialAvailable` 为 true 但喂养未达标
- **THEN** 客户端 MUST NOT 展示「免费体验」按钮
- **AND** MUST NOT 经由 soft access 进入 care 详情
- **AND** MUST NOT claim

### Requirement: Unlock hub SHALL show free-trial button on the right when eligible
When a catalog item is locked and `trialAvailable` is true (care additionally feeding-qualified), the unlock hub feature card button row SHALL show「免费体验」as the rightmost action. Tapping it MUST open a confirm dialog stating each user has only one free trial; confirming「体验」MUST navigate to the detail page. VIP or unlocked items MUST NOT show the button. When care feeding is unqualified, the entire unlock CTA row (including free-trial) MUST be hidden per `feature-unlock-hub` unqualified rules. 开通页在有资格时 **必须** 在按钮行最右侧展示「免费体验」；care 未达标时整行开通 CTA **不得** 展示。

#### Scenario: Show and confirm
- **WHEN** `trialAvailable` 为 true 且功能未开通且（非 care 或 care 已喂养达标）
- **THEN** 开通卡 MUST 显示最右侧「免费体验」；确认「体验」后 MUST 进入详情

#### Scenario: Hidden when unlocked
- **WHEN** 功能已有效开通或 VIP
- **THEN** MUST NOT 显示「免费体验」

#### Scenario: Hidden when care feeding unqualified
- **WHEN** care 卡 `trialAvailable` 为 true 但喂养未达标
- **THEN** MUST NOT 显示「免费体验」
