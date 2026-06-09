## MODIFIED Requirements

### Requirement: Compose text input SHALL use keyboard bridge with emoji-only overlay

The compose body `ManagedKeyboardTextField` with `scene: ucg.compose.body` MUST attach with default config: `showEmoji` true; `showMultimedia`, `showInputField`, and `showConfirmButton` false. The page body field MUST remain editable. Local draft persistence MUST NOT bind to overlay confirm; it remains on exit dialog, publish success, and explicit save paths only.

发布正文必须仅启用全局 emoji 浮层；页面正文可编辑；不得将本地草稿持久化绑定到浮层「确定」。

#### Scenario: compose 无浮层输入与确定
- **WHEN** 用户在发布页聚焦正文
- **THEN** 全局浮层 SHALL 仅展示 emoji accessory 与面板
- **AND** SHALL NOT 展示浮层输入框或「确定」按钮
- **AND** 玻璃 panel 内正文 Field SHALL 可编辑

#### Scenario: compose emoji 插入正文
- **WHEN** 用户在 compose emoji 面板点选 emoji
- **THEN** 系统 SHALL 插入至正文 controller 当前选区

#### Scenario: compose 失焦不写 SP
- **WHEN** 用户在 compose 正文输入后失焦且未通过退出对话框或发表保存
- **THEN** 系统 SHALL NOT 因 overlay 失焦 alone 写入本地草稿 SP

## REMOVED Requirements

### Requirement: Compose body input SHALL support emoji via confirm bar full mirror

**Reason**: compose 改为 emoji-only 浮层，无浮层草稿镜像与确定。

**Migration**: 见 MODIFIED「emoji-only overlay」条款。
