## ADDED Requirements

### Requirement: Post comment SHALL use full overlay editor with send label

For `ucg.post.comment`, attach MUST use default config: `showEmoji`, `showInputField`, and `showConfirmButton` true; `showMultimedia` false; `confirmLabel` MUST be「发送」. The page comment field MUST be read-only while editing; overlay confirm MUST invoke comment send.

帖子评论必须使用完整浮层编辑；最右按钮文案为「发送」；页面只读。

#### Scenario: 评论浮层发送
- **WHEN** 用户在评论 Sheet 聚焦且点击浮层「发送」
- **THEN** App SHALL 执行与 Sheet 发送等价的评论提交逻辑

#### Scenario: 评论浮层含 emoji 无多媒体
- **WHEN** 用户在评论 Sheet 聚焦
- **THEN** 浮层 SHALL 展示 emoji 与输入框
- **AND** SHALL NOT 展示多媒体缩略条（`showMultimedia` false）
