## ADDED Requirements

### Requirement: Qualified-but-locked feeding analysis SHALL open invite unlock dialog

When feeding eligibility is qualified and care-alert is not effectively unlocked (and not VIP-covered), tapping the unlock prompt on the AI analysis feeding module SHALL open the shared invite-code glass dialog instead of navigating directly to the unlock hub. The dialog title MUST be「智能分析」. The body MUST congratulate the user and state that entering an invite code redeems smart-analysis quota for the catalog item’s `inviteDurationDays` (using existing duration copy rules; omit or soften the day count when the field is unavailable). The dialog MUST provide「获取邀请码」on the left and「开通」on the right. 合格未开通时点击开通引导 **必须** 先弹出共享邀请码玻璃框（标题「智能分析」、正文含邀请授予天数折中话术、左获取邀请码、右开通），**不得** 直接进入开通中心。

#### Scenario: Open dialog from heartbeat prompt

- **WHEN** 用户在 AI 分析页喂养模块处于合格未开通态并点击开通引导文案
- **THEN** 客户端 MUST 展示邀请码玻璃弹框
- **AND** 标题 MUST 为「智能分析」
- **AND** 确认按钮文案 MUST 为「开通」
- **AND** MUST NOT 在点击当下直接 `push` `/features/unlock`

#### Scenario: Get invite code

- **WHEN** 用户在该弹框点击「获取邀请码」
- **THEN** 客户端 MUST 进入邀请码获取方式页（`/features/invite-howto` 或等价）

#### Scenario: Open without code goes to unlock hub

- **WHEN** 用户点击「开通」且邀请码输入为空（trim 后）
- **THEN** 客户端 MUST 导航至开通中心 `/features/unlock`
- **AND** MUST NOT 调用 invite-codes/redeem

#### Scenario: Redeem with code stays on analysis page

- **WHEN** 用户点击「开通」且输入了非空邀请码
- **THEN** 客户端 MUST 调用 invite-codes/redeem，且 `featureId` 为 `care_alert_smart_remind`
- **AND** 兑换成功后 MUST Toast 成功并刷新 feature catalog
- **AND** MUST 留在 AI 分析页（不得仅为成功而强制进开通中心）

#### Scenario: Body uses invite grant days from catalog

- **WHEN** care-alert catalog 项提供了 `inviteDurationDays`
- **THEN** 弹框正文 MUST 体现该邀请授予时长（折中话术：恭喜获得试用资格，输入邀请码即可兑换 x 天/永久智能分析使用额度）
- **AND** MUST NOT 使用付费 `products[].durationDays` 作为该 x
