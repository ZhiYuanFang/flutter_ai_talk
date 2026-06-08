## ADDED Requirements

### Requirement: UCG managed inputs SHALL support Unicode emoji insertion at cursor

All five UCG managed keyboard input scenes (`ucg.chat`, `ucg.compose.body`, `ucg.post.comment`, `ucg.profile.nickname`, `ucg.profile.bio`) MUST allow inserting Unicode emoji at the current text selection via the keyboard-top confirm bar workflow. Inserted emoji MUST be plain UTF-8 text written to the bound `TextEditingController` and `draftText`; the client MUST NOT use custom sticker assets or non-text payloads for this capability.

五处 UCG 受管控输入必须支持在光标/选区处插入 Unicode emoji；插入结果为 UTF-8 纯文本并同步至 controller 与确认条草稿，不得使用自定义贴纸或非文本载荷。

#### Scenario: 从表情面板插入 emoji
- **WHEN** 用户在任一 UCG 受管控输入场景打开表情面板并点选某个 Unicode emoji
- **THEN** 系统 SHALL 在该输入 binding 的当前选区处插入 emoji 字符
- **AND** 键盘顶部确认条草稿镜像 SHALL 立即反映更新后的全文

#### Scenario: emoji 经现有 API 提交
- **WHEN** 用户在聊天或评论场景插入 emoji 后点击「确定」完成提交
- **THEN** App SHALL 将含 emoji 的 UTF-8 文本经现有发送/评论 API 提交，无需新增后端字段

### Requirement: Emoji toggle SHALL appear ONLY on keyboard-top confirm bar accessory

For UCG scenes, the keyboard ↔ emoji toggle control MUST be rendered exclusively on the keyboard-top confirm bar accessory row. The client MUST NOT add emoji toggle buttons adjacent to the page `TextField`, `UcgInputDock`, or other inline input chrome.

UCG 场景的键盘/表情切换入口必须且仅能出现在键盘顶部确认条 accessory 区域；不得在 TextField 旁或 UcgInputDock 上增加表情按钮。

#### Scenario: 聊天页 dock 无表情按钮
- **WHEN** 用户在 UCG 聊天页查看输入 dock
- **THEN** 输入 dock SHALL NOT 展示 emoji 切换按钮
- **AND** emoji 切换 SHALL 仅可通过键盘顶部确认条 accessory 触发

#### Scenario: 确认条展示微信式切换
- **WHEN** 用户在 UCG 受管控输入场景聚焦且确认条可见
- **THEN** 确认条 accessory SHALL 提供键盘与表情面板之间的切换控件（微信式 toggle）

### Requirement: Confirm bar SHALL remain visible during emoji panel mode

When the bound UCG input is in emoji panel mode, the keyboard-top confirm bar MUST remain visible with both the floating draft mirror and the「确定」button, even when `MediaQuery.viewInsets.bottom` is zero or the system keyboard is hidden.

UCG 输入处于表情面板模式时，即使系统键盘收起、viewInsets 为零，键盘顶部确认条仍必须展示浮动草稿镜像与「确定」按钮。

#### Scenario: 表情模式下草稿与确定仍可见
- **WHEN** 用户在 UCG 场景从键盘切换到表情面板且 binding 仍有效
- **THEN** 确认条 SHALL 保持可见
- **AND** 左侧草稿镜像与右侧「确定」按钮 SHALL 仍可交互（确定行为遵循各 scene 既有映射）

#### Scenario: 表情模式切回键盘
- **WHEN** 用户在表情面板模式点击 accessory 切回键盘
- **THEN** 系统 SHALL 重新唤起系统软键盘并保持当前 draft 与选区语义一致

### Requirement: UCG emoji input SHALL NOT include custom stickers

The UCG emoji capability MUST be limited to Unicode emoji characters selectable from an emoji panel. Custom sticker packs, image stickers, and animated stickers are out of scope for this capability.

本能力仅涵盖 Unicode emoji 面板选择；自定义贴纸、图片表情、动图贴纸不在范围内。

#### Scenario: 面板仅提供 Unicode emoji
- **WHEN** 用户打开 UCG 表情面板
- **THEN** 面板 SHALL 仅展示可插入的 Unicode emoji 选项
- **AND** SHALL NOT 提供贴纸 Tab 或图片表情上传入口
