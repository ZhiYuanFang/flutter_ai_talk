## ADDED Requirements

### Requirement: VoiceAsrWsClient MUST accumulate silence-segment finals within one utterance

Within a single client utterance (`beginUtterance` until `endUtterance` / `cancelUtterance`), the cloud MAY emit multiple `asr_final` frames due to silence VAD (segment lock). `VoiceAsrWsClient` MUST treat each pre-commit `asr_final` as a committed segment append, MUST expose `committed + current partial` via `onPartial`, and MUST NOT treat the first `asr_final` as end-of-utterance. Whole-utterance completion MUST wait until after the client sends `commit` (then final / `asr_no_result` / timeout). Feature code and future realtime-translation reuse MUST NOT implement a parallel “first final wins” path. 单次 utterance 内云端 MAY 因静音多次 `asr_final`；`VoiceAsrWsClient` **必须**句段累积并通过 `onPartial` 上送全文；**不得**将首次 `asr_final` 视为整轮结束；整轮收束 **必须**在 client `commit` 之后。

#### Scenario: Pause then continue speech

- **WHEN** 用户按住云端 ASR 说话产生第一段后静音触发 `asr_final`，再继续说话产生第二段 partial
- **THEN** `onPartial` MUST 呈现已锁定第一段与第二段草稿的拼接全文，MUST NOT 仅显示第二段覆盖第一段

#### Scenario: Release after multi-segment

- **WHEN** 上述多段后用户松手触发 `endUtterance`（`commit`）
- **THEN** 返回文本 MUST 包含各段累积结果（语义上覆盖停顿前后所说内容），MUST NOT 仅等于第一次中途 `asr_final`

#### Scenario: Cancel discards accumulation

- **WHEN** 用户取消本次 utterance
- **THEN** 客户端 MUST 丢弃本轮累积且 MUST NOT 将中途段 final 当作有效提交文本

## MODIFIED Requirements

### Requirement: 云端语音转写 WebSocket

The client MUST connect to `/voice/asr/ws` without an auth frame, send a JSON `start` with `deviceNo` and audio parameters, stream PCM s16le as binary frames, and handle `asr_partial` and `asr_final` text JSON messages. `asr_partial` is the unstable draft for the current segment; `asr_final` MAY arrive multiple times before client `commit` as silence-locked segments and MUST be accumulated by `VoiceAsrWsClient`. 客户端必须连接语音转写 WebSocket（路径 `/voice/asr/ws`），连接后发送 `start`（含 `deviceNo`、16kHz/16bit/单声道），按住期间上传裸 PCM 二进制帧，并解析下行 `asr_partial`（当前段预览）与 `asr_final`（静音锁定的句段，commit 前可多次，须累积）。

#### Scenario: 按住说话一轮

- **WHEN** 用户选择云端引擎并按住说话后松开
- **THEN** 客户端必须发送 `commit` 与 `end`，并使用 `endUtterance` 返回的**累积全文**作为指令载荷（非空时调用 `sendCommand`）
