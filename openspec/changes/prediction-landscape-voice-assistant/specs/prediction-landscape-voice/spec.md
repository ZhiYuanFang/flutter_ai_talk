## ADDED Requirements

### Requirement: 预测横屏 MUST 前台常驻唤醒监听（Android 与 iOS）

While the smart prediction page is the visible home pager page and orientation is landscape and the app is in the foreground, the client MUST run on-device wake-word listening for the phrase **「你好，胖宝」** (or an equivalent configured keyword matching that phrase) on **both Android and iOS**, without requiring the user to press a hold-to-talk control. Listening MUST stop when leaving landscape prediction (portrait, other pager page, app backgrounded, or dispose). The client MUST NOT require background / lock-screen always-on wake for this change. 当智能预测页为可见主页、为横屏且 App 处于前台时，客户端 MUST 在 **Android 与 iOS** 上对唤醒词 **「你好，胖宝」**（或等价已配置关键词）常驻本地监听，MUST NOT 要求用户按住说话。离开预测横屏（竖屏、其它页、进后台或 dispose）时 MUST 停止监听。本变更 MUST NOT 要求后台/锁屏常听唤醒。

#### Scenario: Android 横屏前台开始听

- **WHEN** 用户在 Android 进入智能预测页横屏、App 前台且麦克风权限已授予
- **THEN** 客户端 MUST 启动本地唤醒监听

#### Scenario: iOS 横屏前台开始听

- **WHEN** 用户在 iOS 进入智能预测页横屏、App 前台且麦克风权限已授予
- **THEN** 客户端 MUST 启动本地唤醒监听

#### Scenario: 离开横屏停止听

- **WHEN** 用户从预测横屏回到竖屏或滑到喂养/广场
- **THEN** 客户端 MUST 停止本地唤醒监听

#### Scenario: 进后台停止听

- **WHEN** App 从预测横屏前台进入后台
- **THEN** 客户端 MUST 停止本地唤醒监听
- **AND** MUST NOT 在后台继续采集麦克风用于唤醒

### Requirement: 麦克风权限 MUST 先用途说明再系统申请

Before the first microphone access needed for landscape wake listening (or dialogue uplink) when permission is not yet granted, the client MUST show an in-app rationale dialog explaining the microphone purpose (landscape wake phrase and voice dialogue transcription; not background recording), and MUST request the OS microphone permission only after the user confirms. If the user cancels the rationale or the OS denies permission, the client MUST NOT start wake listening and MUST surface a clear status in the landscape listen affordance. If permission is already granted, the client MUST skip the rationale dialog. 当横屏唤醒监听（或对话上送）首次需要麦克风且尚未授权时，客户端 MUST 先展示应用内用途说明弹框（说明含：横屏唤醒词与语音对话转写；非后台录音），仅在用户确认后再请求系统麦克风权限。用户取消用途框或系统拒绝权限时，MUST NOT 启动唤醒监听，并 MUST 在左下监听入口给出可读状态。若权限已授予，MUST 跳过用途框。

#### Scenario: 未授权时先弹用途框

- **WHEN** 用户进入预测横屏且麦克风尚未授权
- **THEN** 客户端 MUST 先展示应用内用途说明弹框
- **AND** MUST NOT 在用户确认前直接弹出系统麦克风权限框（或等价地 MUST NOT 在未确认时发起系统申请）

#### Scenario: 确认后申请系统权限

- **WHEN** 用户在用途说明弹框中确认继续
- **THEN** 客户端 MUST 发起系统麦克风权限申请
- **AND** 若用户授予权限，客户端 MUST 启动本地唤醒监听

#### Scenario: 取消用途框

- **WHEN** 用户在用途说明弹框中取消
- **THEN** 客户端 MUST NOT 启动本地唤醒监听
- **AND** 左下角状态文案 MUST 提示需要麦克风权限才能语音唤醒

### Requirement: 唤醒后 MUST 本地播放「我在」并展示字幕

On wake-word detection, the client MUST play a local preset utterance **「我在」** (not waiting for server TTS for this prompt) and MUST show that text in the landscape subtitle toast region. 检测到唤醒词后，客户端 MUST 播放本地预置「我在」（不得为该提示等待服务端 TTS），并 MUST 在横屏字幕 toast 区展示该文案。

#### Scenario: 唤醒播报

- **WHEN** 本地 KWS 命中「你好，胖宝」
- **THEN** 客户端 MUST 播放本地「我在」
- **AND** 字幕区 MUST 出现「我在」

### Requirement: 唤醒后 MUST 以 PCM 上送后续语音并连接 chat WS

After wake acknowledgement, the client MUST ensure `/voice/chat/ws` is connected (connect on landscape entry or on wake if deferred), stream subsequent user speech as **PCM on both Android and iOS** per `voice-chat-ws` (server-side STT), and present server `thinking_delta` / `answer` / ASR text in the subtitle region while playing TTS audio. The client MUST NOT complete the dialogue turn via `type=text` in this change. 唤醒确认后，客户端 MUST 确保已连接 `/voice/chat/ws`（可在进入横屏时连接或唤醒时补连），按 `voice-chat-ws` 在 **Android 与 iOS** 上均以 **PCM** 上送后续用户语音（服务端 STT），并在字幕区展示服务端 `thinking_delta`/`answer`/ASR 文案，同时播放 TTS。本变更 MUST NOT 以 `type=text` 完成对话话轮。

#### Scenario: 横屏进入即准备通道

- **WHEN** 用户进入预测横屏且已绑定 `deviceNo`
- **THEN** 客户端 MUST 建立或复用 `/voice/chat/ws` 连接（或在首次唤醒前完成可接受的等价就绪策略，但唤醒后首轮对话 MUST 可上送）

#### Scenario: 双端 PCM 上送

- **WHEN** 用户在 Android 或 iOS 预测横屏唤醒后说话
- **THEN** 客户端 MUST 以 PCM 二进制上送该轮语音
- **AND** MUST NOT 以 `type=text` 代替该轮 PCM

#### Scenario: 思考字幕

- **WHEN** 服务端下发 `thinking_delta`
- **THEN** 横屏字幕区 MUST 展示该思考内容（可累积）

### Requirement: 左下角监听状态 UI

In landscape prediction, the client MUST show a listening affordance anchored to the **physical screen** bottom-start (left in LTR), not merely the event-grid pane's bottom-start (i.e. it MAY overlay the identity rail region). The affordance MUST include an icon and horizontal caption text that wraps when too long; the caption MUST communicate listening / wake-word guidance including 「你好，胖宝」. 预测横屏 MUST 在**整屏**左下（LTR）展示监听入口（MUST NOT 仅相对事件网格左下；MAY 叠在身份栏区域之上）：图标 + 横向说明文案，超长 MUST 换行；文案 MUST 传达监听/唤醒指引并包含「你好，胖宝」。

#### Scenario: 整屏左下角可见

- **WHEN** 预测页横屏且语音监听功能启用
- **THEN** 监听图标与说明文案 MUST 锚定在屏幕物理左下附近（相对整页布局，而非仅瀑布流面板）

### Requirement: 字幕区位置

Spoken and server text shown for the landscape voice session MUST appear in a bottom-upper subtitle region (approximately the lower half subtitle band), as toast-like overlay copy, without permanently occupying the identity rail. 横屏语音会话中展示的播报文案与服务端文案 MUST 出现在底部偏上的字幕区域（约半屏字幕带），以 toast 类浮层呈现，MUST NOT 永久占据身份栏。

#### Scenario: 字幕不贴物理底边独占

- **WHEN** 展示「我在」或 thinking/answer 字幕
- **THEN** 文案区域 MUST 位于屏幕底部偏上
- **AND** MUST NOT 替代事件网格为主内容

### Requirement: 喂养语音球逐步废弃（规划）

After landscape voice assistant ships as the primary voice entry, the feeding-page hold-to-talk voice orb MUST be treated as deprecated for product direction; this change MAY hide or soften the orb entry but is NOT required to delete all orb code in the same change. 横屏语音助手作为主语音入口上线后，喂养页按住说话语音球 MUST 在产品方向上视为废弃；本变更 MAY 隐藏或弱化球入口，但不要求同变更删除全部球代码。

#### Scenario: 文档化废弃

- **WHEN** 本变更新增横屏语音主路径
- **THEN** OpenSpec/任务 MUST 标明喂养球逐步废弃
- **AND** 完整拆除 MAY 留待后续 change
