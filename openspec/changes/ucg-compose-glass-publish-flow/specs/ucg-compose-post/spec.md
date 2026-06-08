## MODIFIED Requirements

### Requirement: Compose screen SHALL use minimal surface sections

The compose screen form sections (text, media preview, action chips) MUST use a single `HistoryEditGlassPanel` (feeding-module glass morphism) wrapping body text, 9-grid media, and AI polish action together. The compose screen MUST NOT use separate `UcgSurfaceCard` wrappers for these sections. Drag-to-delete overlay at screen bottom MAY remain non-glass (WeChat-style red bar).

发布页正文、九宫格与 AI润笔须包在同一块喂养风格 `HistoryEditGlassPanel` 内，不得再用分散的 `UcgSurfaceCard`。底部拖拽删除条可保持微信红条非玻璃样式。

#### Scenario: 单块玻璃编辑区
- **WHEN** 用户打开发布页
- **THEN** 正文、九宫格与 AI润笔（若可见）SHALL 位于同一块 `HistoryEditGlassPanel` 内
- **AND** App SHALL NOT 为上述区域分别使用 `UcgSurfaceCard`

#### Scenario: 九宫格玻璃圆角
- **WHEN** 发布页展示图片缩略图格
- **THEN** 每个图片 cell SHALL 使用约 12–14px 圆角与玻璃语言轻描边（非 2px 微信直角）

### Requirement: Compose text input SHALL use keyboard bridge

The compose body `TextField` MUST remain implemented via `ManagedKeyboardTextField` with `scene: ucg.compose.body` and `resizeToAvoidBottomInset: false`. Glass styling MUST NOT break keyboard confirm bar attachment. Placeholder SHOULD use copy such as「这一刻的想法…」.

正文须继续使用 `ManagedKeyboardTextField` 与键盘确认条；玻璃样式不得破坏 bridge；占位符建议「这一刻的想法…」。

#### Scenario: 玻璃内键盘确认条
- **WHEN** 用户在 glass panel 内聚焦正文
- **THEN** 键盘顶部 SHALL 仍显示确认条
- **AND** 页面主体 SHALL NOT 因键盘整体上移

## ADDED Requirements

### Requirement: Compose header SHALL use WeChat-style cancel and publish row without title

The compose screen MUST NOT display a page title or subtitle. The top bar MUST show「取消」on the left and a primary-filled「发表」capsule on the right in the same row. The publish button MUST use `ColorScheme.primary` / `onPrimary` from the baby theme.

发布页不得展示标题/副标题；顶栏须为同排「取消 | 发表」；发表按钮须使用宝宝主题 primary 胶囊。

#### Scenario: 无标题顶栏
- **WHEN** 用户打开发布页
- **THEN** UI SHALL NOT 展示「发布动态」等标题或副标题文案
- **AND** 顶栏 SHALL 仅含取消与发表操作

#### Scenario: 发表按钮主题色
- **WHEN** 用户查看发表按钮
- **THEN** 按钮背景 SHALL 使用 `Theme.of(context).colorScheme.primary`

### Requirement: Compose exit dialog SHALL use glass styling when content exists

When closing compose with non-empty content, the three-action dialog (save draft / discard / cancel) MUST use glass dialog styling (`showGlassDialog` or equivalent), not Material `AlertDialog`.

有内容时关闭发布页的三选对话框须使用玻璃 dialog，不得使用 Material `AlertDialog`。

#### Scenario: 玻璃三选对话框
- **WHEN** 用户在有内容时触发关闭
- **THEN** App SHALL 展示玻璃风格对话框，含保存草稿、放弃、取消

### Requirement: Compose page SHALL have body-only input without title field

The compose screen MUST provide a single editable body text field inside the glass panel. The compose screen MUST NOT include a separate title field.

发布页仅在 glass panel 内提供正文输入，不得有独立标题字段。

#### Scenario: 无标题输入框
- **WHEN** 用户打开发布页
- **THEN** UI SHALL 仅展示正文输入，无标题输入框
