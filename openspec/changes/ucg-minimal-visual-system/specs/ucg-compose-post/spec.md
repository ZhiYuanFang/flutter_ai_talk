## ADDED Requirements

### Requirement: Compose screen SHALL use minimal surface sections

The compose screen form sections (text, media preview, action chips) MUST use `ucg-visual-system` light-surface or bare `shellColor` partitions. They MUST NOT use `UcgShellGlassCard` glass morphism wrappers.

发布页表单分区必须使用简约轻表面或裸 shell 分区，不得使用玻璃拟态卡片包裹。

#### Scenario: 发布页无玻璃分区
- **WHEN** 用户打开发布动态页
- **THEN** 正文区、媒体预览区 SHALL NOT 使用 `BackdropFilter` 磨砂玻璃容器

### Requirement: Compose text input SHALL use keyboard bridge

The compose body `TextField` MUST be implemented via `ManagedKeyboardTextField` (or equivalent attach pattern) with `resizeToAvoidBottomInset: false` on the compose scaffold. `onConfirm` SHALL unfocus and persist draft (MUST NOT auto-publish on confirm unless product explicitly maps publish—default: unfocus + draft save).

发布正文输入必须接入键盘确认条；点「确定」默认收起键盘并保存草稿，不自动发帖。

#### Scenario: 发布正文键盘确认条
- **WHEN** 用户在发布页聚焦正文输入框
- **THEN** 键盘顶部 SHALL 显示确认条，且页面主体 SHALL NOT 因键盘整体上移

#### Scenario: 确定保存草稿
- **WHEN** 用户在发布正文场景点击确认条「确定」
- **THEN** App SHALL 回填文本至正文 controller、执行草稿持久化，并收起键盘
