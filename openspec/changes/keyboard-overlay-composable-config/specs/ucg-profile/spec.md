## MODIFIED Requirements

### Requirement: Profile nickname and bio editing SHALL use overlay full editor

For `ucg.profile.nickname` and `ucg.profile.bio`, attach MUST use default config: `showEmoji`, `showInputField`, and `showConfirmButton` true; `showMultimedia` false; `confirmLabel`「确定」. Static profile display MUST remain read-only while editing; overlay TextField MUST be the primary editor.

资料昵称/简介必须使用完整浮层编辑（含 emoji）；页面只读；浮层「确定」提交。

#### Scenario: 资料编辑浮层完整
- **WHEN** 用户点击编辑昵称或简介
- **THEN** 全局浮层 SHALL 展示 emoji、浮层输入框与「确定」
- **AND** 资料页静态文本 SHALL 只读展示当前 draft

#### Scenario: 昵称失焦丢弃
- **WHEN** 用户在昵称编辑中未点「确定」即失焦
- **THEN** 系统 SHALL 恢复 attach 快照
- **AND** SHALL NOT 调用保存 `onConfirm`
