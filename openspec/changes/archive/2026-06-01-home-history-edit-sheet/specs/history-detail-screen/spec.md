## REMOVED Requirements

### Requirement: 历史详情删除当前事件

**Reason**: 全屏历史详情页已移除；删除能力迁移至主页 `home-history-edit-sheet` Bottom Sheet。

**Migration**: 用户在主页点击历史行，在编辑 Sheet 内执行删除。

### Requirement: 事件名与动作只读、备注可编辑

**Reason**: 全屏历史详情页已移除；同等语义由主页编辑 Sheet 承担。

**Migration**: 在 `home-history-edit-sheet` 中编辑备注；事件名在 Sheet 标题区只读展示。

### Requirement: eventNumber 为 0 时可编辑开始与结束时间

**Reason**: 全屏历史详情页已移除；时间编辑改为 Sheet 内 Cupertino 滚轮时分。

**Migration**: 见 `home-history-edit-sheet` 规格。

### Requirement: eventNumber 为 1 时仅可编辑结束时间

**Reason**: 全屏历史详情页已移除。

**Migration**: 见 `home-history-edit-sheet` 规格。

### Requirement: eventNumber 大于 1 时可编辑结束时间与用量

**Reason**: 全屏历史详情页已移除；用量改为与添加一致的滚轮。

**Migration**: 见 `home-history-edit-sheet` 规格。

### Requirement: 编辑入口与底部保存

**Reason**: 预览/编辑双模式全屏页已废止；主页 Sheet 直接进入可编辑态，无 AppBar 编辑入口。

**Migration**: 点击历史行即打开可编辑 Sheet，底部提供保存按钮。

### Requirement: 不展示创建时间

**Reason**: 全屏历史详情页已移除；Sheet 内同样不得展示 `createdAt`（由 `home-history-edit-sheet` 继承该约束）。

**Migration**: 编辑 Sheet 不展示创建时间行。
