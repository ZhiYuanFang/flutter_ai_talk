## ADDED Requirements

### Requirement: UCG module text inputs SHALL adopt keyboard-top confirm bar

All managed text input fields in the UCG module (`app/lib/ucg/`) that open the system keyboard MUST attach to `keyboardInputBridgeController` using `ManagedKeyboardTextField` or the equivalent documented attach/detach/`updateDraft` pattern. This includes at minimum: chat message input, compose body, post detail comment sheet, and profile nickname/bio editors.

UCG 模块内所有会唤起系统键盘的受管控输入框必须接入键盘顶部确认条，至少覆盖：聊天、发布正文、详情评论、资料昵称/简介。

#### Scenario: UCG 聊天接入确认条
- **WHEN** 用户在 UCG 聊天页聚焦消息输入
- **THEN** 系统 SHALL 展示键盘顶部确认条，且 UCG 页面 SHALL 保持 `resizeToAvoidBottomInset: false` 行为

#### Scenario: UCG 评论 Sheet 不顶起改用桥接
- **WHEN** 用户在帖子详情打开评论输入并聚焦
- **THEN** Sheet SHALL NOT 依赖 `respectKeyboardInset: true` 整体上移；输入 MUST 通过键盘确认条镜像与提交

### Requirement: New UCG features SHALL default to managed keyboard input

New UCG screens or widgets that add editable `TextField`s MUST use `ManagedKeyboardTextField` (or equivalent) by default unless explicitly documented as exempt in spec.

UCG 后续新增功能若包含可编辑输入框，默认必须使用受管控输入封装，除非规格明确豁免。

#### Scenario: 新 UCG 输入默认受管控
- **WHEN** 开发者在 UCG 模块新增会弹键盘的 `TextField`
- **THEN** 实现 MUST 使用 `ManagedKeyboardTextField` 或等效 attach 模式，且父 Scaffold MUST 设置 `resizeToAvoidBottomInset: false`
