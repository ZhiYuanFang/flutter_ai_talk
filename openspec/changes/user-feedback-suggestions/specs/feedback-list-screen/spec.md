## ADDED Requirements

### Requirement: Feedback list screen SHALL use settings glass morphism visual system

The feedback list screen MUST NOT use raw UCG minimal cards (`UcgSurfaceCard` or equivalent) as primary containers. It MUST use the settings-center glass visual system: gradient scaffold background (shell → primaryContainer blend), transparent `AppBar`, and `_SettingsGlassPanel` (or extracted shared equivalent) for list cards, empty state, and bottom input dock. Blur, border radius (~22), and gradient border styling MUST match `settings_screen.dart` conventions.

反馈列表页 MUST 使用设置中心玻璃拟态，不得使用裸 UCG 简约卡片。

#### Scenario: 页面背景与 AppBar
- **WHEN** 用户打开反馈列表页
- **THEN** Scaffold SHALL 使用与设置中心一致的渐变背景
- **AND** AppBar SHALL 为透明样式、标题「反馈建议」

#### Scenario: 列表项玻璃卡片
- **WHEN** 页面展示一条或多条历史反馈
- **THEN** 每条记录 SHALL 包裹在玻璃 panel 内（圆角、blur、渐变描边）
- **AND** SHALL NOT 使用 UCG 白底简约卡片作为主容器

#### Scenario: 底部输入 dock 玻璃样式
- **WHEN** 用户查看页面底部提交区域
- **THEN** 输入区与「提交」按钮 SHALL 置于玻璃 panel dock 内
- **AND** 提交按钮 SHALL 使用 `ColorScheme.primary` 胶囊样式

### Requirement: Feedback list screen SHALL display history with question and official reply

The screen MUST load the current user's feedback via `GET /device/app/api/feedback/list` on open (and after successful submit). Each item MUST show the user's `question`. If `officialReply` is present, it MUST be displayed as the official response; otherwise the UI MUST show a subdued「等待官方回复」(or equivalent) placeholder. Items MUST be ordered newest first (matching API).

反馈列表页须展示用户问题与官方回复（或等待回复占位）。

#### Scenario: 展示已回复记录
- **WHEN** 某条反馈 `officialReply` 非空
- **THEN** 列表项 SHALL 同时展示用户问题与官方回复正文

#### Scenario: 展示待回复记录
- **WHEN** 某条反馈尚无官方回复
- **THEN** 列表项 SHALL 展示用户问题
- **AND** SHALL 展示弱化文案表明等待官方回复

#### Scenario: 提交后刷新列表
- **WHEN** 用户成功提交新反馈
- **THEN** 列表 SHALL 刷新并置顶显示新记录
- **AND** 输入框 SHALL 清空

### Requirement: Feedback list screen SHALL provide empty state welcome text

When the user has no feedback history, the screen MUST show a welcome message inside a glass panel (e.g. encouraging the user to share suggestions), instead of a blank list.

无历史记录时须展示玻璃容器内的欢迎引导文案。

#### Scenario: 空列表欢迎态
- **WHEN** API 返回空列表
- **THEN** 页面 SHALL 在玻璃 panel 内展示欢迎/引导文案
- **AND** 底部提交 dock SHALL 仍可用

### Requirement: Feedback list screen SHALL allow submitting new feedback from bottom input

The screen MUST provide a text input and「提交」button in the bottom glass dock. Submit MUST call `POST /device/app/api/feedback/submit` with trimmed `question`. Empty submit MUST be disabled or rejected with user-visible feedback. The dock SHOULD adjust for keyboard `viewInsets`.

底部须提供输入框与提交按钮，调用提交 API。

#### Scenario: 成功提交
- **WHEN** 用户输入非空问题并点击「提交」
- **THEN** App SHALL 调用提交 API
- **AND** 成功时 SHALL toast 或等价提示并刷新列表

#### Scenario: 空内容不可提交
- **WHEN** 输入框仅为空白
- **THEN**「提交」SHALL 为 disabled 或点击后提示不可为空
- **AND** App SHALL NOT 调用提交 API
