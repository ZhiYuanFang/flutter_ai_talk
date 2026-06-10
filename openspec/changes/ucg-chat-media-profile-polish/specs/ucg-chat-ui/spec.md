## MODIFIED Requirements

### Requirement: Chat media selection SHALL use top prefab strip before send

For `ucg.chat`, media picked via attach MUST appear as a pending attachment strip **immediately above the input dock** (same visual layer as the composer, below the message list). The client MUST display **local thumbnails** as soon as selection completes and MUST start OSS upload in the background without blocking the attach flow or disabling text input. The client MUST NOT send media until the user presses dock send. When send is pressed while upload is incomplete, the send button MUST show an in-button loading indicator and the client MUST await upload completion before calling `sendChatMessage`.

聊天 attach 所选媒体须出现在**输入 dock 正上方**的待发送条；选完即本地缩略图展示并后台上传，不得阻塞选图或禁用输入；点发送时若上传未完成，发送按钮须转圈并等待完成后提交。

#### Scenario: 选图后 dock 上方本地预览
- **WHEN** 用户在聊天页通过 attach 选择图片或视频
- **THEN** UI SHALL 在输入 dock 正上方展示可删除的本地缩略预制
- **AND** SHALL NOT 在消息列表顶部展示待发送条
- **AND** SHALL NOT 阻塞至上传完成才展示预览

#### Scenario: 后台上传不阻塞输入
- **WHEN** 待发送媒体后台仍在上传
- **THEN** 消息输入框与 attach 按钮 SHALL 保持可用（除非正在发送消息）
- **AND** App SHALL NOT 展示全屏「正在处理媒体…」阻塞整个 dock

#### Scenario: 发送等待上传
- **WHEN** 用户点击 dock 发送且存在未完成上传的待发送媒体
- **THEN** 发送按钮内 SHALL 显示 `CircularProgressIndicator`
- **AND** App SHALL await 上传完成后调用 `sendChatMessage`

#### Scenario: 发送携带已上传媒体
- **WHEN** 用户点击发送且待发送媒体已上传完成
- **THEN** App SHALL 按现有逻辑提交 `imageKey` 或 `videoKey`

#### Scenario: 上传失败阻止发送
- **WHEN** 发送前等待上传失败且重试仍失败
- **THEN** App SHALL 停止发送按钮 loading
- **AND** App SHALL 展示可读错误且不得发送该条消息

### Requirement: Chat dock SHALL host inline emoji panel below input row

For `ucg.chat`, the client MUST render an emoji toggle on the dock row and an emoji panel directly below the dock. When the user opens emoji while the system keyboard is hidden and no prior keyboard inset was recorded, the panel MUST use a preset minimum height (`KeyboardOverlayMetrics.emojiPanelMinHeight`). When `lastKeyboardInset` is greater than zero, panel height SHOULD approximate that inset.

聊天须在 dock 行展示 emoji 切换，并在 dock 下方展示 emoji 面板；无键盘历史高度时使用预设最小高度。

#### Scenario: 无键盘时 emoji 面板预设高度
- **WHEN** 用户在聊天页未唤起系统键盘时点击 emoji 切换
- **THEN** 系统 SHALL 在 dock 正下方展示 emoji 面板
- **AND** 面板高度 SHALL 不小于 `emojiPanelMinHeight`（约 200 逻辑像素）

#### Scenario: emoji 面板在 dock 下方
- **WHEN** 用户在聊天页点击 dock emoji 切换且系统键盘已弹出
- **THEN** 系统 SHALL 收起系统软键盘
- **AND** SHALL 在 dock 正下方展示 emoji 面板
- **AND** binding SHALL 保持有效

#### Scenario: emoji 面板高度随键盘历史
- **WHEN** emoji 面板展开且 `lastKeyboardInset` 大于零
- **THEN** 面板高度 SHOULD 近似最近一次键盘 inset 高度

### Requirement: Chat input blur without confirm SHALL soft-sync draft

For `ucg.chat`, when the user taps outside the input/emoji region while the emoji panel is visible, the client MUST hide the emoji panel and system keyboard equivalent to dismissing input chrome, while preserving the draft text in the dock controller.

聊天在表情模式下点击输入区外部须收起 emoji 面板（等同收键盘），且须保留输入框草稿文本。

#### Scenario: 表情模式点外部收起
- **WHEN** 用户在聊天页 emoji 面板可见
- **AND** 用户在输入区与 emoji 面板之外点击
- **THEN** emoji 面板 SHALL 隐藏
- **AND** 输入框文本 SHALL 保留

#### Scenario: 表情模式点消息列表收起
- **WHEN** 用户在聊天页 emoji 面板可见且点击消息列表区域
- **THEN** emoji 面板 SHALL 隐藏

## ADDED Requirements

### Requirement: Chat pure media messages SHALL render without bubble background

For messages that contain image and/or video attachment(s) and **no non-empty text**, the client MUST render media without glass/card bubble background for both peer and self messages. Delivery status icon for self pure-media messages MAY appear adjacent to media without wrapping media in the primary gradient bubble.

纯图片或纯视频消息（无正文）必须不包文字气泡底色，自己与对方发送均适用。

#### Scenario: 纯图片无气泡
- **WHEN** 聊天消息仅含图片、无文字
- **THEN** UI SHALL 展示裸图片缩略图（可圆角）
- **AND** SHALL NOT 用 `UcgSurfaceCard` 或渐变玻璃气泡包裹媒体

#### Scenario: 纯视频无气泡
- **WHEN** 聊天消息仅含视频、无文字
- **THEN** UI SHALL 展示裸视频预览/播放器
- **AND** SHALL NOT 包裹文字气泡底色

#### Scenario: 自己纯媒体无气泡
- **WHEN** 当前用户发送纯媒体消息
- **THEN** UI SHALL 同样不包裹 primary 渐变气泡
- **AND** 送达状态图标 MAY 贴于媒体旁

#### Scenario: 图文混合
- **WHEN** 消息同时含媒体与非空文字
- **THEN** 媒体 SHALL 无气泡底色展示
- **AND** 文字部分 SHALL 保留现有文字气泡样式

### Requirement: Chat avatars SHALL navigate to user profile

In the 1:1 chat screen, tapping the peer avatar in the app bar title, tapping either message-row avatar (peer or self), MUST navigate to the corresponding user profile screen (`UcgUserProfileScreen` or owner profile equivalent).

聊天顶栏对方头像与消息行双方头像点击须进入对应用户主页。

#### Scenario: 点击对方消息行头像
- **WHEN** 用户点击对方消息旁头像
- **THEN** App SHALL 打开 `UcgUserProfileScreen(userId: peerId)`

#### Scenario: 点击自己消息行头像
- **WHEN** 用户点击自己消息旁头像
- **THEN** App SHALL 打开当前用户资料页（owner 模式或等价路由）

#### Scenario: 点击顶栏对方头像或昵称区
- **WHEN** 用户点击 AppBar 中对方头像或昵称区域
- **THEN** App SHALL 打开 `UcgUserProfileScreen(userId: peerId)`

#### Scenario: 顶栏自己聊天
- **WHEN** 会话为与自己聊天（peerId 等于当前用户）
- **THEN** 顶栏与消息行头像点击 SHALL 进入当前用户资料页
