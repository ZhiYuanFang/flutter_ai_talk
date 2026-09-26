## ADDED Requirements

### Requirement: Unlock hub SHALL load care-alert feeding eligibility
When the feature unlock hub becomes visible (initial load and pull-to-refresh), the client SHALL ensure care-alert feeding eligibility is loaded via the existing `care-alert/eligibility` path (single-flight). The hub MUST NOT rely solely on other screens having preloaded eligibility. 开通中心可见时 **必须** 自行 ensure care-alert eligibility，**不得** 仅依赖其它页预热。

#### Scenario: Enter hub loads eligibility
- **WHEN** 已登录用户打开功能开通页
- **THEN** 客户端 MUST 触发 care-alert eligibility ensureLoaded（或等价）

#### Scenario: Pull refresh refreshes eligibility
- **WHEN** 用户在开通中心下拉刷新
- **THEN** 客户端 MUST 再次 ensure/刷新 care-alert eligibility

### Requirement: Care unlock-hub card SHALL hide unlock CTAs and toast when feeding unqualified
On the unlock hub card for `care_alert_smart_remind`, when feeding eligibility is not qualified (`qualified != true`, including still loading without a prior qualified cache), the card MUST NOT show payment, invite-code, or free-trial unlock CTAs. The card bottom MUST show an unqualified hint (prefer progress copy from `effectiveDays`/`requiredDays`/`remainingDays` when data is present; otherwise a short unmet-threshold message). Whole-card tap MUST show a Toast stating the feeding threshold is not met and MUST NOT navigate to the feeding detail route. Growth cards MUST remain unaffected. 智能分析卡喂养未达标时 **不得** 展示开通按钮行，底部 **必须** 未达标提示，整卡点击 **必须** Toast 且 **不得** 进详情；成长轨迹不变。

#### Scenario: Unlocked CTAs hidden when unqualified
- **WHEN** care 卡未商业开通且 `qualified=false` 且 catalog 含 payment/invite
- **THEN** MUST NOT 展示支付 / 邀请码 / 免费体验按钮
- **AND** 底部 MUST 展示未达标提示

#### Scenario: Tap toasts when unqualified
- **WHEN** care 卡喂养未达标且用户点击卡片
- **THEN** 客户端 MUST Toast 提示未达标
- **AND** MUST NOT push `/prediction/ai-analysis/feeding`

#### Scenario: Qualified locked shows CTAs again
- **WHEN** care 卡未开通且 `qualified=true`
- **THEN** 开通按钮行 MUST 按既有 payment/invite/trial 规则恢复展示

### Requirement: Care hub detail entry SHALL require continuous feeding qualification
The unlock hub MUST navigate to `/prediction/ai-analysis/feeding` only when commercial access is allowed **and** care-alert feeding eligibility is qualified. This MUST apply even when the feature is effectively unlocked or VIP-covered. If unlocked (or VIP) but unqualified, the card MUST show the unqualified hint instead of entitlement remaining copy, and tap MUST Toast without navigation. 智能分析进详情 **必须** 持续喂养达标；已开通或 VIP 回落未达标时 **不得** 进详情，底部提示 + Toast。

#### Scenario: Unlocked but unqualified cannot enter
- **WHEN** care 卡 `isFeatureEffectivelyUnlocked` 为 true 但 `qualified=false`
- **THEN** 整卡点击 MUST NOT push feeding 详情
- **AND** MUST Toast 未达标
- **AND** 底部 MUST 为未达标提示而非「已开通」剩余天数主展示

#### Scenario: Unlocked and qualified enters detail
- **WHEN** care 卡已有效开通且 `qualified=true` 且用户点击卡片
- **THEN** 客户端 MUST push `/prediction/ai-analysis/feeding`

## MODIFIED Requirements

### Requirement: Opened care-alert and growth cards SHALL navigate to detail subpages

On the feature unlock hub, when a catalog row for `growth_trajectory_predict` is effectively unlocked (`isFeatureEffectivelyUnlocked`, including VIP coverage), tapping the card MUST navigate (push) to `/prediction/ai-analysis/growth`. When a catalog row for `care_alert_smart_remind` is effectively unlocked **and** care-alert feeding eligibility is qualified, tapping the card MUST navigate (push) to `/prediction/ai-analysis/feeding`. The client MUST NOT require an intermediate stop at `/prediction/ai-analysis` for this gesture. The client MUST NOT add chevron, arrow, or「查看」affordance chrome solely for this navigation. When care is unlocked but feeding-unqualified, whole-card tap MUST NOT navigate to feeding detail (Toast per care unqualified rules). When the row is not commercially unlocked, the card MUST NOT navigate to those detail routes via whole-card tap unless other soft-access rules explicitly allow **and** (for care) feeding is qualified; existing unlock CTAs MUST continue to work only when care feeding is qualified. Other feature rows MUST NOT gain detail navigation from this requirement. 成长轨迹有效开通整卡进详情；智能分析 **必须** 有效开通且喂养达标才进详情；care 未达标不得整卡进详情。

#### Scenario: Opened smart analysis card opens feeding detail

- **WHEN** the unlock hub shows an effectively unlocked `care_alert_smart_remind` row
- **AND** feeding eligibility is qualified
- **AND** the user taps the card
- **THEN** the client MUST push `/prediction/ai-analysis/feeding`

#### Scenario: Opened smart analysis unqualified does not open detail

- **WHEN** the unlock hub shows an effectively unlocked `care_alert_smart_remind` row
- **AND** feeding eligibility is not qualified
- **AND** the user taps the card
- **THEN** the client MUST NOT push `/prediction/ai-analysis/feeding`

#### Scenario: Opened growth card opens growth detail

- **WHEN** the unlock hub shows an effectively unlocked `growth_trajectory_predict` row
- **AND** the user taps the card
- **THEN** the client MUST push `/prediction/ai-analysis/growth`

#### Scenario: Locked row does not whole-card navigate

- **WHEN** either of those feature rows is not commercially unlocked and (for care) feeding is qualified so unlock CTAs show
- **THEN** tapping outside the CTA buttons MUST NOT navigate to the detail subpages
- **AND** CTA buttons MUST still open their existing unlock flows

#### Scenario: No arrow chrome

- **WHEN** an opened navigable card is rendered
- **THEN** the card MUST NOT add a dedicated trailing chevron/arrow or「查看」label solely as a navigation affordance
