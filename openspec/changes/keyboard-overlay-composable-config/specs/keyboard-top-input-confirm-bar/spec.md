## ADDED Requirements

### Requirement: Keyboard overlay SHALL be composable via KeyboardOverlayConfig

The keyboard input bridge MUST accept a `KeyboardOverlayConfig` with `showEmoji`, `showMultimedia`, `showInputField`, and `showConfirmButton`. When all four flags are false, the global `KeyboardInputConfirmBarOverlay` MUST NOT render. When `showInputField` is true, the page-bound input MUST be read-only display and the overlay TextField MUST be the primary editor.

键盘桥接必须接受可组合配置；四 bool 均为 false 时不渲染全局浮层；`showInputField` 为 true 时页面输入只读、浮层输入为主编辑器。

#### Scenario: 全 false 不展示全局浮层
- **WHEN** binding 的 config 四项均为 false（如 `ucg.chat`）
- **THEN** 全局 `KeyboardInputConfirmBarOverlay` SHALL NOT 可见
- **AND** 页面输入 SHALL 保持可编辑

#### Scenario: 浮层输入时页面只读
- **WHEN** binding 的 `showInputField` 为 true 且用户聚焦该输入
- **THEN** 页面命中输入 SHALL 以只读展示
- **AND** 浮层 TextField SHALL 接收 IME 输入

### Requirement: Accessory row SHALL place confirm label at far right

When `showConfirmButton` is true, the overlay accessory row MUST lay out controls as: optional emoji and multimedia on the left, optional input field expanded in the center, and the confirm action button with scene-specific `confirmLabel` aligned at the far right.

当展示确定/发送按钮时，accessory 行必须左 accessory、中输入、最右场景化文案按钮。

#### Scenario: 评论浮层右侧发送
- **WHEN** 用户在 `ucg.post.comment` 聚焦且浮层可见
- **THEN** accessory 行最右侧按钮文案 SHALL 为「发送」
- **AND** 点击该按钮 SHALL 执行评论发送 `onConfirm`

#### Scenario: home.text 浮层右侧发送
- **WHEN** 用户在 Web 端 `home.text` 聚焦且浮层可见
- **THEN** accessory 行最右侧按钮文案 SHALL 为「发送」
- **AND** 点击该按钮 SHALL 执行 `_onTextSubmit` 等价逻辑

### Requirement: Keyboard overlay metrics SHALL use unified compact sizing

The overlay MUST use shared `KeyboardOverlayMetrics`: accessory bar height 44 logical px, overlay editor clamped between 36 and 72 logical px with at most 2 lines, emoji panel height derived from `lastKeyboardInset`, consistent on Android and iOS.

浮层必须使用统一紧凑尺寸常量；Android 与 iOS 一致。

#### Scenario: 空态 accessory 高度
- **WHEN** 用户聚焦任一带全局浮层的 scene 且 draft 为空
- **THEN** accessory 行视觉高度 SHALL NOT 超过 44 logical px（不含 emoji 面板）

#### Scenario: emoji 面板高度跟随键盘
- **WHEN** 用户切换到 emoji 面板模式且 `lastKeyboardInset` 已记录
- **THEN** emoji 面板高度 SHALL 不小于 200 logical px
- **AND** SHOULD 近似 `lastKeyboardInset` 减去 accessory 行高度

### Requirement: Component lift SHALL anchor focused input widget

When a managed input attaches with a registered anchor, the client MUST scroll or inset so the anchor widget's bottom edge aligns above the keyboard plus overlay chrome. The anchor MUST be the focused input widget the user tapped, not an unrelated parent container (e.g. whole chat dock).

顶组件必须以用户点击/聚焦的输入控件为锚点底边对齐键盘与浮层，不得错误顶起父级容器。

#### Scenario: 评论 Sheet 顶组件
- **WHEN** 用户在评论 Sheet 内聚焦输入且键盘弹出
- **THEN** 评论输入锚点 SHALL 不被键盘或浮层 accessory 遮挡

### Requirement: Emoji panel mode MUST NOT detach binding on TextInput hide

When `InputMode.emoji` is active, losing system keyboard visibility MUST NOT detach the binding solely due to `TextInput.hide` side effects.

emoji 模式下 hide 系统键盘不得 alone 导致 detach。

#### Scenario: 切换 emoji 后会话保持
- **WHEN** 用户在带 emoji 的 binding 中点击 emoji 切换且系统键盘收起
- **THEN** binding SHALL 保持有效
- **AND** 用户 SHALL 可继续点选 emoji 插入文本

## MODIFIED Requirements

### Requirement: 统一键盘顶部输入确认条展示

The system SHALL present a keyboard-top overlay for managed inputs according to `KeyboardOverlayConfig`, not a fixed confirm bar for all scenes. When any config flag is true, the overlay MUST render only the enabled sections. When all flags are false, the overlay MUST NOT render. For emoji panel mode with an active binding, the overlay MUST remain visible even when `MediaQuery.viewInsets.bottom` is zero.

系统必须按可组合配置展示键盘顶部浮层，而非所有 scene 统一完整确认条；emoji 模式下 binding 有效时浮层必须保持可见。

#### Scenario: 仅 emoji 浮层
- **WHEN** 用户在 `ucg.compose.body` 聚焦且 config 仅 `showEmoji` 为 true
- **THEN** 全局浮层 SHALL 展示 emoji accessory 与面板
- **AND** SHALL NOT 展示浮层输入框或「确定」按钮

#### Scenario: 登录注册页面内直接输入
- **WHEN** 用户在 `login.*`、`register.*`、`change-password.*`、`baby-bind.*` 或 `baby-profile.nickname` 聚焦
- **THEN** 全局浮层 SHALL NOT 渲染
- **AND** 页面 TextField SHALL 直接接收 IME 输入（非 readOnly）

#### Scenario: UCG 表情模式下浮层仍展示
- **WHEN** binding 处于 emoji 面板模式且 config 含 `showEmoji`
- **THEN** 浮层 SHALL 可见，即使系统键盘已隐藏

## REMOVED Requirements

### Requirement: UCG confirm bar accessory SHALL host emoji keyboard toggle

**Reason**: emoji 入口改为按 `KeyboardOverlayConfig` 与 scene 分流；`ucg.chat` 在 dock 内提供 emoji，不再要求所有 UCG scene 在浮层 accessory 展示切换。

**Migration**: 使用 `resolveOverlayConfig(scene)`；聊天见 `ucg-chat-ui` dock 条款。

### Requirement: Confirm bar draft mirror SHALL support multiline display

**Reason**: 草稿只读镜像由浮层可编辑 TextField 取代（`showInputField` 场景）；仅 emoji 场景无浮层输入区。

**Migration**: 浮层 TextField `maxLines: 2` 与 internal scroll 见 `KeyboardOverlayMetrics`。

### Requirement: Long-press draft mirror SHALL offer newline insertion for eligible scenes

**Reason**: 换行改由浮层 TextField 原生多行或 Web fallback 处理；聊天无全局浮层镜像。

**Migration**: fullEditor 场景在浮层 TextField 内换行；聊天在 dock Field 内换行。
