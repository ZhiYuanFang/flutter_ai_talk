## ADDED Requirements

### Requirement: Compose body input SHALL support emoji and newline via confirm bar

The compose body input (`scene: ucg.compose.body`) MUST support Unicode emoji insertion and newline insertion through the keyboard-top confirm bar. The compose form MUST NOT add inline emoji buttons beside the body field.

发布正文输入必须经键盘顶部确认条支持 emoji 与换行；发布表单不得在正文字段旁增加 inline emoji 按钮。

#### Scenario: 发布正文插入 emoji
- **WHEN** 用户在发布页聚焦正文并通过确认条表情面板插入 emoji
- **THEN** 正文 controller 与 draft SHALL 更新
- **AND** 点击「确定」 SHALL 执行既有草稿保存与 unfocus 逻辑

#### Scenario: 发布正文长按换行
- **WHEN** 用户在 `ucg.compose.body` 场景长按确认条草稿并选择「换行」
- **THEN** 系统 SHALL 在正文当前选区插入换行符

### Requirement: Compose blur without confirm SHALL soft-sync without local draft persistence

When the compose body input loses focus without confirm bar「确定」, the client MUST soft-sync `draftText` to the body controller, MUST NOT invoke compose `onConfirm`, and MUST NOT write to the local compose draft file. Navigating away from the compose screen MAY discard in-field text per existing product rules.

发布正文在未点「确定」而失焦时，必须 soft-sync draft 至 controller，不得调用 `onConfirm`，不得写入本地草稿文件；离开发布页时可按既有规则丢弃页内未确认文本。

#### Scenario: 失焦不写本地草稿
- **WHEN** 用户在发布页编辑正文但未点「确定」即失焦
- **THEN** 正文输入框 SHALL 显示当前 draft 文本
- **AND** App SHALL NOT 触发本地草稿文件持久化

#### Scenario: 确定仍保存草稿
- **WHEN** 用户在发布正文场景点击确认条「确定」
- **THEN** App SHALL 回填文本、执行本地草稿持久化，并收起键盘（与变更前行为一致）

## MODIFIED Requirements

### Requirement: Compose text input SHALL use keyboard bridge

The compose body `TextField` MUST be implemented via `ManagedKeyboardTextField` (or equivalent attach pattern) with `resizeToAvoidBottomInset: false` on the compose scaffold. `onConfirm` SHALL unfocus and persist draft (MUST NOT auto-publish on confirm). Blur without confirm MUST soft-sync to controller only.

发布正文输入必须接入键盘确认条；点「确定」默认收起键盘并保存草稿；失焦未确定仅 soft-sync 至 controller。

#### Scenario: 发布正文键盘确认条
- **WHEN** 用户在发布页聚焦正文输入框
- **THEN** 键盘顶部 SHALL 显示确认条（含 emoji accessory），且页面主体 SHALL NOT 因键盘整体上移

#### Scenario: 确定保存草稿
- **WHEN** 用户在发布正文场景点击确认条「确定」
- **THEN** App SHALL 回填文本至正文 controller、执行草稿持久化，并收起键盘
