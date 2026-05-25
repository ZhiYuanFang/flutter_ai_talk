## ADDED Requirements

### Requirement: 底部弹框最大高度为屏幕三分之二

All modal bottom sheets launched from the app bottom MUST constrain their visible content height to at most two-thirds (2/3) of the screen height. **所有**自底部弹出的 `showModalBottomSheet`（或等价）内容区 **必须**满足 `maxHeight ≤ screenHeight × 2/3`。

#### Scenario: 内容超出最大高度

- **WHEN** Sheet 内容固有高度大于屏幕 2/3
- **THEN** 客户端 MUST 将 Sheet 高度限制在 2/3 屏内，且 MUST 在内部提供可滚动区域承载溢出内容

#### Scenario: 内容少于最大高度

- **WHEN** Sheet 内容固有高度小于屏幕 2/3
- **THEN** Sheet 实际高度 MUST 等于内容高度（加 safe area / 键盘 inset），且 MUST NOT 固定占满 2/3 屏

### Requirement: 共享自适应布局组件

The client SHALL provide a shared layout helper (e.g. `AppAdaptiveBottomSheet`) used by bottom sheets to enforce the max-height and intrinsic-height rules consistently. 新建与迁移的 Sheet **应该**通过该 helper 或等价约束实现，避免各文件重复硬编码 `height: screen * 2/3`。

#### Scenario: 事件目录 picker 迁移

- **WHEN** 用户打开 `showEventCatalogPickerSheet`
- **THEN** Sheet MUST 遵循 max 2/3 与内容自适应规则（不得无条件固定 `SizedBox(height: 2/3)`）

#### Scenario: number 添加 Sheet

- **WHEN** 用户打开 `showHomeNumberEventSheet`
- **THEN** Sheet MUST 在内容较少时自适应高度，且 MUST NOT 超过 2/3 屏

#### Scenario: 历史编辑 Sheet

- **WHEN** 用户打开历史记录编辑 Sheet
- **THEN** Sheet MUST 使用与上述一致的布局约束

#### Scenario: 回复展示 Sheet

- **WHEN** 用户打开 `showHomeReplyBottomSheet`
- **THEN** Sheet MUST 将整体 max 高度设为 2/3 屏（取代或对齐现有 55% 内容区特例），内容少时仍自适应

### Requirement: 键盘与安全区内边距

The shared bottom sheet layout MUST account for `viewInsets` (keyboard) and bottom safe padding so fields remain reachable without breaking the max-height rule.

#### Scenario: 备注输入聚焦

- **WHEN** Sheet 内 TextField 获得焦点且键盘弹出
- **THEN** 布局 MUST 增加 bottom inset padding，且 MUST NOT 使 Sheet 可见区域超过 2/3 屏与键盘占用的合理组合（内容可内滚）
