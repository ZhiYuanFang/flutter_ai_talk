## ADDED Requirements

### Requirement: 云端语音转写 WebSocket

The client MUST connect to `/voice/asr/ws` without an auth frame, send a JSON `start` with `deviceNo` and audio parameters, stream PCM s16le as binary frames, and handle `asr_partial` and `asr_final` text JSON messages. 客户端必须连接语音转写 WebSocket（路径 `/voice/asr/ws`），连接后发送 `start`（含 `deviceNo`、16kHz/16bit/单声道），按住期间上传裸 PCM 二进制帧，并解析下行 `asr_partial`（预览）与 `asr_final`（完整一句）。

#### Scenario: 按住说话一轮

- **WHEN** 用户选择云端引擎并按住说话后松开
- **THEN** 客户端必须发送 `commit` 与 `end`，并使用 `asr_final` 的文本作为指令载荷（非空时调用 `sendCommand`）

### Requirement: 平台默认语音识别引擎

The client MUST default speech engine to cloud ASR on Android and system STT on iOS when no user preference is stored. 未保存用户偏好时，**Android** 默认必须为**云端实时转写**；**iOS** 默认必须为**系统语音识别**。

#### Scenario: 首次安装 Android

- **WHEN** Android 用户首次打开设置中心查看语音识别
- **THEN** 默认选中项必须为云端实时转写

### Requirement: 语音转写连接断开反馈

The client MUST surface voice ASR WebSocket disconnection on the home voice control and MUST attempt reconnect before the next utterance when cloud ASR is selected. 云端模式下 WebSocket 断开时，主页语音控件必须提示未连接；用户再次按住时必须先尝试重连，成功后才可开始 `start` 与上传音频。

#### Scenario: 断线后再次按住

- **WHEN** 云端模式下语音 WebSocket 已断开且用户按住说话
- **THEN** 客户端必须先连接 WebSocket，失败则提示且不得开始上传音频
