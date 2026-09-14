## ADDED Requirements

### Requirement: Opened care-alert and growth cards SHALL navigate to detail subpages

On the feature unlock hub, when a catalog row for `care_alert_smart_remind` or `growth_trajectory_predict` is effectively unlocked (`isFeatureEffectivelyUnlocked`, including VIP coverage), tapping the card MUST navigate (push) to the corresponding detail route: feeding analysis at `/prediction/ai-analysis/feeding` for care-alert, and growth trajectory at `/prediction/ai-analysis/growth` for growth. The client MUST NOT require an intermediate stop at `/prediction/ai-analysis` for this gesture. The client MUST NOT add chevron, arrow, or「查看」affordance chrome solely for this navigation. When the row is not effectively unlocked, the card MUST NOT navigate to those detail routes via whole-card tap; existing unlock CTAs MUST continue to work. Other feature rows (including prediction slot) MUST NOT gain detail navigation from this requirement. 有效开通的智能分析 / 成长轨迹卡 **必须** 整卡可点直达对应详情子页；**不得** 强制经 AI 分析 Hub；**不得** 为此增加箭头等暗示控件；未开通不得靠整卡跳详情。

#### Scenario: Opened smart analysis card opens feeding detail

- **WHEN** the unlock hub shows an effectively unlocked `care_alert_smart_remind` row
- **AND** the user taps the card
- **THEN** the client MUST push `/prediction/ai-analysis/feeding`

#### Scenario: Opened growth card opens growth detail

- **WHEN** the unlock hub shows an effectively unlocked `growth_trajectory_predict` row
- **AND** the user taps the card
- **THEN** the client MUST push `/prediction/ai-analysis/growth`

#### Scenario: Locked row does not whole-card navigate

- **WHEN** either of those feature rows is not effectively unlocked and shows unlock CTAs
- **THEN** tapping outside the CTA buttons MUST NOT navigate to the detail subpages
- **AND** CTA buttons MUST still open their existing unlock flows

#### Scenario: No arrow chrome

- **WHEN** an opened navigable card is rendered
- **THEN** the card MUST NOT add a dedicated trailing chevron/arrow or「查看」label solely as a navigation affordance
