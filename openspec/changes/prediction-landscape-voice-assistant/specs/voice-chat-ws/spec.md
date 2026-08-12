## ADDED Requirements

### Requirement: App MUST 实现 `/voice/chat/ws` 客户端（仅 PCM 上行）

The Flutter app MUST implement a dedicated `/voice/chat/ws` client that connects without JWT auth, sends JSON `start` with `deviceNo` and PCM parameters matching the existing hardware/ASR configuration (`mode=stream`, 16 kHz, 16-bit, mono unless server contract changes), and streams user speech as PCM s16le binary frames on both Android and iOS. The client MAY send `commit` and `end`. For this change, the client MUST NOT use `type=text` as the dialogue turn uplink. 客户端 MUST 实现专用 `/voice/chat/ws` 客户端：无 JWT 鉴权；`start` 含 `deviceNo` 与现网硬件/ASR 一致的 PCM 参数；**Android 与 iOS** 均以二进制帧上送用户语音 PCM s16le；MAY 发送 `commit`/`end`。本变更范围内客户端 MUST NOT 以 `type=text` 作为对话话轮上行。

#### Scenario: start 与 PCM 上行（双端）

- **WHEN** 用户在 Android 或 iOS 上开始一轮语音对话上送
- **THEN** MUST 先发送合法 `start`（含 `deviceNo` 与 `mode=stream`）
- **AND** MUST 以二进制帧上送 PCM
- **AND** MUST NOT 依赖 `type=text` 完成本轮用户话轮

#### Scenario: 本期无 text 上行

- **WHEN** 实现本变更的 App chat WS 客户端
- **THEN** MUST NOT 将 `type=text` 作为交付范围内的对话上送路径

### Requirement: 客户端 MUST 解析思考、答案与流式音频帧

The client MUST parse server JSON frames including at least `asr_partial`, `asr_final`, `thinking_delta`, `answer`, `audio_chunk`, `audio_end`, `interrupt_commit`, `exit`, and `error`. Thinking subtitle text MUST come from `thinking_delta` (or documented equivalent server thinking frames) and MUST NOT be fabricated locally. Final reply text MUST be taken from `answer` when present. TTS playback MUST consume `audio_chunk` / `audio_end` as today on hardware. Unknown types MUST be ignored without disconnecting. 客户端 MUST 解析至少含 `asr_partial`、`asr_final`、`thinking_delta`、`answer`、`audio_chunk`、`audio_end`、`interrupt_commit`、`exit`、`error` 的服务端 JSON 帧。思考字幕 MUST 来自 `thinking_delta`（或已文档化的等价思考帧），MUST NOT 本地编造。最终回复文案在存在 `answer` 时 MUST 取自该帧。TTS 播放 MUST 消费 `audio_chunk`/`audio_end`。未知 type MUST 忽略且不得因此断连。

#### Scenario: 思考来自服务端

- **WHEN** 服务端下发一条或多条 `thinking_delta`
- **THEN** 客户端 MUST 将 delta 累积/展示为思考文案
- **AND** MUST NOT 用本地模板替换为虚假思考

#### Scenario: 答案与 TTS

- **WHEN** 服务端下发 `answer` 随后 `audio_chunk`/`audio_end`
- **THEN** 客户端 MUST 可展示 `answer.text`（或约定字段）
- **AND** MUST 播放流式音频

#### Scenario: 旧帧兼容

- **WHEN** 服务端尚未下发 `thinking_delta`/`answer`（仅 ASR+TTS）
- **THEN** 客户端 MUST 仍能完成音频播放
- **AND** MUST NOT 因缺少思考帧而失败整轮

### Requirement: PCM 与转写配置 MUST 对齐现网

Sample rate, bit depth, channels, and stream mode for `/voice/chat/ws` MUST align with the existing voice ASR / hardware chat configuration used by the product unless an explicit server contract change says otherwise. Speech-to-text for App landscape dialogue MUST be performed by the server (Baidu STT via chat WS) in this change; on-device STT for dialogue uplink is out of scope. `/voice/chat/ws` 的采样率、位深、声道与 stream 模式 MUST 与现网语音 ASR/硬件对话配置一致，除非服务端契约明确变更。本变更中 App 横屏对话的语音转写 MUST 由服务端（经 chat WS 的 Baidu STT）完成；对话上行的端侧 STT 不在范围。

#### Scenario: 16k 单声道

- **WHEN** 客户端发送 `start`
- **THEN** 默认音频参数 MUST 为 16 kHz、16-bit、单声道、`mode=stream`（或与当时现网 ASR 客户端常量一致）
