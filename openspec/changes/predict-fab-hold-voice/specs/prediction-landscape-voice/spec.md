## MODIFIED Requirements

### Requirement: 预测横屏 MUST 前台常驻唤醒监听（Android 与 iOS）

While the **landscape** prediction voice session is active and the app is in the foreground, the client MUST run on-device wake-word listening for the phrase **「胖宝」** on **both Android and iOS** in **landscape**, without requiring the user to press a hold-to-talk control. The keyword line MUST keep boost `:2.0` and threshold `#0.25`. `keywordsThreshold` MUST stay `0.25` and `keywordsScore` MUST stay `1.5`. The client MUST NOT raise any of these scores to compensate for the shorter phrase. Listening MUST stop when the landscape session is inactive, the app is backgrounded, the controller is disposed, or the UI leaves landscape prediction voice. The client MUST NOT run this always-on wake path for portrait prediction (portrait uses go-record PTT instead). The client MUST NOT require background / lock-screen always-on wake.

预测**横屏**语音会话在前台激活时，客户端 MUST 在 Android 与 iOS 横屏上对「胖宝」常驻本地监听；MUST NOT 要求按住说话。关键词分数阈值保持不变。离开横屏会话/进后台/dispose 时 MUST 停止。竖屏 MUST NOT 走本常驻唤醒（竖屏为去记录 PTT）。MUST NOT 要求后台/锁屏常听。

#### Scenario: Android 横屏前台开始听

- **WHEN** 用户在 Android 进入已激活的预测横屏语音、App 前台且麦克风权限已授予
- **THEN** 客户端 MUST 启动对「胖宝」的本地唤醒监听
- **AND** MUST NOT 提高既有唤醒分数阈值

#### Scenario: iOS 横屏前台开始听

- **WHEN** 用户在 iOS 进入已激活的预测横屏语音、App 前台且麦克风权限已授予
- **THEN** 客户端 MUST 启动对「胖宝」的本地唤醒监听

#### Scenario: 竖屏不启常驻唤醒

- **WHEN** 用户停留在预测竖屏（无横屏语音会话）
- **THEN** 客户端 MUST NOT 因竖屏可见而启动「胖宝」常驻唤醒监听

#### Scenario: 进后台停止听

- **WHEN** App 从已激活的预测横屏语音进入后台
- **THEN** 客户端 MUST 停止本地唤醒监听
- **AND** MUST NOT 在后台继续采集麦克风用于唤醒

### Requirement: 麦克风权限 MUST 先用途说明再系统申请

Before the first microphone access needed for prediction wake listening (or dialogue uplink) when permission is not yet granted, the client MUST show an in-app rationale dialog explaining the microphone purpose (wake phrase and/or voice dialogue transcription; not background recording), and MUST request the OS microphone permission only after the user confirms. That first access MUST be triggered by an explicit user gesture: tap on the landscape listen chip, or long-press on the portrait go-record pill (or equivalent listen affordance), NOT merely by the prediction voice surface becoming visible or by lifecycle `activate` on surface want. When the surface becomes visible and permission is not granted, the client MUST only perform a non-prompting grant check, MUST NOT show the rationale dialog, and MUST NOT call OS permission request APIs. If the user cancels the rationale or the OS denies permission, the client MUST NOT start wake listening / PTT uplink and MUST surface a clear status. If permission is already granted at gesture time, the client MUST skip the rationale dialog.

当预测唤醒或对话上送首次需要麦克风且尚未授权时，MUST 先用途说明再系统申请；首次访问 MUST 由横屏点 chip 或竖屏长按「去记录」触发，MUST NOT 仅因表面可见触发。

#### Scenario: 表面可见未授权不弹框

- **WHEN** 用户进入预测横屏或竖屏预测表面，且麦克风尚未授权
- **THEN** 客户端 MUST NOT 展示应用内用途说明弹框
- **AND** MUST NOT 发起系统麦克风权限申请

#### Scenario: 点横屏监听入口未授权时先弹用途框

- **WHEN** 用户点按横屏监听 chip，且麦克风尚未授权，且本会话未处于「已拒绝不再硬弹」熔断
- **THEN** 客户端 MUST 先展示应用内用途说明弹框
- **AND** MUST NOT 在用户确认前直接发起系统申请

#### Scenario: 竖屏长按未授权时先弹用途框

- **WHEN** 用户长按「去记录」进入 PTT，且麦克风尚未授权，且未熔断
- **THEN** 客户端 MUST 先展示应用内用途说明弹框
- **AND** MUST NOT 在用户确认前直接发起系统申请

### Requirement: 唤醒后 MUST 以 PCM 上送后续语音并连接 chat WS

After wake acknowledgement on **landscape**, the client MUST ensure `/voice/chat/ws` is connected, stream subsequent user speech as **PCM on both Android and iOS** per `voice-chat-ws` (server-side STT), present server `thinking_delta` / `answer` / ASR text in the subtitle region, and MUST play TTS audio for landscape replies (`outputModality=audio` or server default audio). The client MUST NOT complete the landscape dialogue turn via `type=text` uplink. 横屏唤醒后 MUST PCM 上送并展示思考/答复，且 MUST 播放 TTS；MUST NOT 以 `type=text` 作为用户话轮上行。

#### Scenario: 横屏进入即准备通道

- **WHEN** 用户进入预测横屏且已绑定 `deviceNo`
- **THEN** 客户端 MUST 建立或复用 `/voice/chat/ws` 连接（或在首次唤醒前完成可接受的等价就绪策略，但唤醒后首轮对话 MUST 可上送）

#### Scenario: 双端 PCM 上送

- **WHEN** 用户在 Android 或 iOS 预测横屏唤醒后说话
- **THEN** 客户端 MUST 以 PCM 二进制上送该轮语音
- **AND** MUST NOT 以 `type=text` 代替该轮 PCM

#### Scenario: 思考字幕与 TTS

- **WHEN** 服务端下发 `thinking_delta` 与后续 audio 帧
- **THEN** 横屏字幕区 MUST 展示思考内容（可累积）
- **AND** 客户端 MUST 播放 TTS 音频（audio 输出）

## ADDED Requirements

### Requirement: Landscape dialogue start MUST request audio output modality

When starting a landscape prediction voice chat audio session (`start` after wake or listen-chip tap), the client MUST use `outputModality=audio` (explicitly or by documented default equivalent to audio) so the server synthesizes TTS. Portrait PTT MUST NOT reuse a stale text-modality session after rotating to landscape without an `end`→`start` retarget. 横屏对话 `start` MUST 为 audio 输出；旋转后 MUST NOT 沿用竖屏 text 会话窗。

#### Scenario: Landscape start is audio

- **WHEN** 用户在预测横屏开始一轮 chat `start`
- **THEN** 该 `start` MUST 使服务端按 audio 输出（可下发 `audio_chunk`/`audio_end`）
