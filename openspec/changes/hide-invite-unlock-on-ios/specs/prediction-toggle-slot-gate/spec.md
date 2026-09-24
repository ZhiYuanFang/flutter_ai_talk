## REMOVED Requirements

### Requirement: Forecast toggle consumes permanent slots
**Reason**: 预测槽位商业开通（含满额邀码兑换 `prediction_unlock`）产品能力已删除；与同能力下「Forecast toggle SHALL not be gated by prediction slot cap」及 `user-scoped-feature-commerce` 的「Prediction slot commerce SHALL be removed」冲突。
**Migration**: 以「Forecast toggle SHALL not be gated by prediction slot cap」为准；开启预测不得再弹「预测槽位已满」邀码框，也不得按 `allowedCount` 商业闸拦截。

### Requirement: Excess enabled forecasts MUST be aligned by slot cap
**Reason**: 依赖已删除的永久槽位商业闸与满额再开对话框语义。
**Migration**: 不再按 `prediction_unlock.allowedCount` 对齐或裁剪预测开关；非商业规则若另有定义则单独规格。

### Requirement: Slot-full dialog copy MAY reference defaultCount without changing the gate
**Reason**: 满额槽位确认/邀码对话框已删除。
**Migration**: 无；`prediction-catalog-default-count` 若仍描述其它非商业文案可独立保留，但不得再引用 slot-full 邀码闸。

### Requirement: Slot-full invite dialog MUST brand with prediction_unlock catalog logo and color
**Reason**: 满额共享邀码弹窗已删除。
**Migration**: 无；共享邀码弹窗仅服务开通中心等现存邀请开通路径（见 `invite-code-howto`）。

## ADDED Requirements

### Requirement: Prediction page MUST drop dead invite-code dialog import
The smart prediction screen SHALL NOT import or reference the shared invite-code dialog solely for the removed slot-full unlock flow. 智能预测页 **不得** 仅为已删除的槽位满额邀码流程保留对共享邀请码弹窗的引用。

#### Scenario: No unused invite dialog import
- **WHEN** 检查 `smart_prediction_screen.dart` 源码
- **THEN** MUST NOT 存在对 `feature_unlock/invite_code_dialog.dart` 的无用 import
- **AND** MUST NOT 存在「预测槽位已满」邀码开通调用路径
