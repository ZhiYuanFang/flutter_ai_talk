## MODIFIED Requirements

### Requirement: 共享自适应布局组件

The client SHALL provide shared layout helpers for bottom sheets: non-glass sheets MAY use `AppAdaptiveBottomSheet` / `showAppAdaptiveBottomSheet`, and glass sheets MUST use the glass overlay entry that internally reuses the same max-height and scroll rules. 新建与迁移的底部 Sheet MUST 通过共享 helper 实现高度约束；**玻璃态** Sheet MUST 使用 `showGlassAdaptiveBottomSheet`（或等价）而非各自重复 `showModalBottomSheet` 样板代码。

#### Scenario: 事件目录 picker 迁移

- **WHEN** 用户打开 `showEventCatalogPickerSheet`
- **THEN** Sheet MUST 遵循 max 2/3 与内容自适应规则，且 MUST 通过玻璃 overlay 入口展示

#### Scenario: number 添加 Sheet

- **WHEN** 用户打开 `showHomeNumberEventSheet`
- **THEN** Sheet MUST 在内容较少时自适应高度，且 MUST NOT 超过配置的 max 高度比例；MUST 通过玻璃 overlay 入口展示

#### Scenario: 历史编辑 Sheet

- **WHEN** 用户打开历史记录编辑 Sheet
- **THEN** Sheet MUST 使用与上述一致的布局约束，且 MUST 通过玻璃 overlay 入口展示

#### Scenario: 回复展示 Sheet

- **WHEN** 用户打开 `showHomeReplyBottomSheet`
- **THEN** Sheet MUST 将整体 max 高度设为不超过 2/3 屏，内容少时仍自适应，且 MUST 使用玻璃 overlay 入口

### Requirement: 历史编辑 Sheet 透明外层

All glass bottom sheets launched through the glass overlay entry MUST use a transparent modal bottom sheet background with the inner glass panel providing visible chrome. 凡通过玻璃 overlay 入口打开的底部 Sheet MUST 使用 **transparent** 的 modal 背景，由内部 `HistoryEditGlassPanel` 承担圆角与填充。

#### Scenario: 玻璃 Sheet 一致外层

- **WHEN** 用户打开任一已迁移的玻璃 Bottom Sheet（含目录 picker、回复、时分选择）
- **THEN** MUST NOT 将 `colorScheme.surface` 或 `themePrimaryBlend` 作为 sheet 可见底板

#### Scenario: 非玻璃 Sheet 仍可独立

- **WHEN** 未来存在明确不需要玻璃的视觉的底部 Sheet
- **THEN** 该 Sheet MAY 继续使用 `showAppAdaptiveBottomSheet` 默认 Material 背景，但 MUST 仍遵守 2/3 屏高规则
