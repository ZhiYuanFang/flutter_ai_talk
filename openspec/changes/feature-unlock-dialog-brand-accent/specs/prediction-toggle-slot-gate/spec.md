## ADDED Requirements

### Requirement: Slot-full invite dialog MUST brand with prediction_unlock catalog logo and color

When the smart prediction page blocks enabling forecast because the permanent slot is full (non-VIP, enabledCount >= allowedCount), the shared invite-code dialog MUST be shown with branding from the feature catalog item whose `featureId` is `prediction_unlock`: `logoUrl` MUST be that item’s `logo` (empty string if missing), and `eventAccent` MUST be `resolveFeatureColor` for that item. Title「预测槽位已满」、confirm「激活」、how-to / redeem / empty-code → unlock-hub flows MUST remain as specified by prior slot-gate requirements. 满额共享邀请码弹窗 **必须** 带预测槽位 catalog 的 logo 与功能色；文案与兑码业务流保持既有约定。

#### Scenario: Branded slot-full dialog

- **WHEN** a non-VIP user tries to enable a new forecast while slots are full and catalog contains `prediction_unlock`
- **THEN** the shared invite dialog MUST open with that item’s logo and resolved feature color
- **AND** the confirm button MUST use that feature color as its background

#### Scenario: Missing catalog item still shows dialog

- **WHEN** slots are full but the `prediction_unlock` catalog item is not yet available
- **THEN** the dialog MUST still open
- **AND** accent MUST fall back via `resolveFeatureColor(null)` / theme primary
- **AND** logo MAY be the FeatureLogo placeholder
