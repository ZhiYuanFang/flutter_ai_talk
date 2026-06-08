## MODIFIED Requirements

### Requirement: 统一键盘顶部输入确认条展示

The system SHALL present a keyboard-top input confirm bar for managed text input fields when they gain focus. For UCG scenes in emoji panel mode, the confirm bar MUST remain visible while the binding is active even if the system keyboard is hidden.

系统在受管控输入框获得焦点时，必须在键盘上方展示统一输入确认条；该确认条至少包含左侧输入文本显示区与右侧「确定」按钮。UCG 场景在表情面板模式下，binding 有效时确认条必须保持可见。系统在输入框失焦且非表情面板模式、或 binding 解除后，不得继续显示该确认条。

#### Scenario: 聚焦后展示确认条
- **WHEN** 用户在受管控页面或弹层中点击可编辑输入框并触发键盘弹出
- **THEN** 系统在键盘上方显示输入确认条，且右侧提供可点击「确定」按钮

#### Scenario: 确认条展示当前输入场景提示
- **WHEN** 用户在确认条中尚未输入任何内容
- **THEN** 确认条左侧文本区以占位样式展示该输入场景的 hint，说明当前输入框所代表的内容（如账号、密码、备注等）
- **WHEN** 用户已输入内容
- **THEN** 确认条左侧文本区展示当前输入内容（密码场景仍为脱敏展示），不再显示 hint

#### Scenario: UCG 表情模式下确认条仍展示
- **WHEN** UCG 受管控输入处于表情面板模式且 binding 未解除
- **THEN** 确认条 SHALL 可见，且 SHALL 展示草稿镜像与「确定」按钮

## ADDED Requirements

### Requirement: Confirm bar draft mirror SHALL support multiline display

The keyboard-top confirm bar floating draft text area MUST support multiline rendering for managed inputs. It MUST NOT be limited to a single line with ellipsis-only overflow when displaying UCG or other managed draft content (password obscured display rules unchanged).

键盘顶部确认条左侧草稿镜像必须支持多行展示，不得仅以单行省略号截断 UCG 等受管控输入的草稿内容（密码脱敏规则不变）。

#### Scenario: 多行草稿完整可见
- **WHEN** 用户在 UCG 发布正文或聊天场景输入含换行符的多行文本
- **THEN** 确认条草稿区 SHALL 以多行形式展示文本（可在限定行数内滚动）
- **AND** SHALL NOT 强制单行 `TextOverflow.ellipsis` 作为唯一展示方式

### Requirement: Long-press draft mirror SHALL offer newline insertion for eligible scenes

For managed inputs where newline insertion is allowed, a long-press on the confirm bar draft mirror MUST present a context menu with a「换行」action that inserts a newline at the current selection via the keyboard input bridge.

在允许换行的受管控场景中，长按确认条草稿镜像必须弹出含「换行」的菜单，并通过桥接层在当前选区插入换行符。

#### Scenario: 聊天场景长按换行
- **WHEN** 用户在 `ucg.chat` 场景长按确认条草稿镜像
- **THEN** 系统 SHALL 展示含「换行」的菜单
- **WHEN** 用户选择「换行」
- **THEN** 系统 SHALL 在当前选区插入换行符并更新草稿与 controller

#### Scenario: 昵称场景不得提供换行菜单
- **WHEN** 用户在 `ucg.profile.nickname` 场景长按确认条草稿镜像
- **THEN** 系统 SHALL NOT 展示「换行」菜单或等效换行入口

#### Scenario: 密码场景不得提供换行菜单
- **WHEN** 用户在 `obscureText` 为 true 的受管控输入场景长按确认条草稿镜像
- **THEN** 系统 SHALL NOT 展示「换行」菜单

### Requirement: Detach without confirm SHALL follow scene-specific blur policy

When a managed input binding is detached without the user pressing「确定」, the keyboard input bridge MUST apply the blur policy configured for that scene: profile nickname/bio scenes MUST discard draft and restore the attach-time snapshot without invoking `onConfirm`; chat, post comment, and compose body scenes MUST soft-sync `draftText` to the target controller without invoking `onConfirm` and without compose local draft file persistence on blur alone.

受管控输入在未点击「确定」而失焦 detach 时，桥接层必须按 scene 执行 blur 策略：资料昵称/简介必须丢弃草稿并恢复 attach 快照且不调用 `onConfirm`；聊天、评论、发布正文必须将 draft 软同步回 controller 且不调用 `onConfirm`，且发布正文失焦 alone 不得写入本地草稿文件。

#### Scenario: 资料昵称失焦丢弃
- **WHEN** 用户在 `ucg.profile.nickname` 编辑中修改文本但未点「确定」即失焦
- **THEN** 系统 SHALL 恢复编辑开始时的昵称快照
- **AND** SHALL NOT 调用昵称保存 `onConfirm`

#### Scenario: 聊天失焦软同步
- **WHEN** 用户在 `ucg.chat` 场景输入但未点「确定」即失焦
- **THEN** 系统 SHALL 将当前 `draftText` 写回消息输入 controller
- **AND** SHALL NOT 触发发送消息 `onConfirm`

#### Scenario: 发布正文失焦不写本地草稿
- **WHEN** 用户在 `ucg.compose.body` 场景输入但未点「确定」即失焦
- **THEN** 系统 SHALL 将 `draftText` 软同步至正文 controller
- **AND** SHALL NOT 持久化至本地草稿文件
- **AND** SHALL NOT 调用发布页 `onConfirm`

### Requirement: UCG confirm bar accessory SHALL host emoji keyboard toggle

For bindings whose `scene` identifies a UCG managed input (`ucg.*`), the keyboard-top confirm bar MUST include an accessory control to toggle between system keyboard mode and emoji panel mode. Non-UCG scenes MUST NOT show this toggle.

scene 为 UCG 受管控输入时，确认条必须提供键盘/表情面板切换 accessory；非 UCG 场景不得展示该切换控件。

#### Scenario: UCG 场景展示 emoji 切换
- **WHEN** 用户在 `ucg.post.comment` 场景聚焦评论输入
- **THEN** 键盘顶部确认条 accessory SHALL 展示 emoji/键盘切换控件

#### Scenario: 喂养场景不展示 emoji 切换
- **WHEN** 用户在喂养模块 home 文本输入场景聚焦
- **THEN** 确认条 SHALL NOT 展示 UCG emoji 切换 accessory
