## MODIFIED Requirements

### Requirement: UCG inline surfaces SHALL use minimal light-surface styling

UCG inline cards, list rows, input docks, and bottom navigation on Tab pages (广场、消息、我的等) MUST continue to use minimal styling without `BackdropFilter` glass. **Exception:** the **publish flow** (compose entry bottom sheet, camera sub-sheet, custom album picker page, compose screen glass panel, compose exit glass dialog) MAY use `HistoryEditGlassPanel` and feeding-module glass morphism. This exception MUST NOT apply to feed cards, message list rows, or profile inline sections.

Tab 内联 UI 仍须简约无玻璃；**例外**：发布动线（入口 sheet、拍摄子 sheet、自建相册页、发布页 glass panel、退出 glass dialog）允许使用喂养模块玻璃拟态；该例外不得扩展到广场 Feed 卡片、消息列表或我的资料内联区。

#### Scenario: 广场 Feed 仍无玻璃
- **WHEN** 用户在广场 Tab 浏览 Feed
- **THEN** 帖子卡片 SHALL NOT 使用 `BackdropFilter` 玻璃容器

#### Scenario: 发布动线允许玻璃
- **WHEN** 用户从「+」进入发布流程（sheet、相册页或 compose）
- **THEN** App MAY 使用 `HistoryEditGlassPanel` 或等价玻璃 overlay 组件

## ADDED Requirements

### Requirement: Publish flow glass SHALL reuse feeding-module components

Glass surfaces in the publish flow MUST reuse existing feeding-module primitives (`HistoryEditGlassPanel`, `showGlassAdaptiveBottomSheet`, `showGlassDialog`, `historyEditGlassTextColor`, etc.) rather than introducing a separate UCG-only glass theme. Accent color SHOULD use `ColorScheme.primary` as `eventAccent`.

发布动线玻璃须复用喂养模块现有组件，accent 建议使用 `ColorScheme.primary`，不得另起独立 UCG 玻璃色板。

#### Scenario: 复用 HistoryEditGlassPanel
- **WHEN** 发布页渲染主编辑区
- **THEN** App SHALL 使用 `HistoryEditGlassPanel`（或对其的 thin wrapper）
- **AND** App SHALL NOT 复制一套独立 blur 参数而不复用现有组件
