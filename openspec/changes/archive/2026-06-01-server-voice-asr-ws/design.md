## Context

- URL：`AppEnv.wsVoiceAsrUrlEffective` → `ws(s)://{host}/voice/asr/ws`（可用 `WS_VOICE_ASR_URL` 覆盖）。
- 无鉴权；`deviceNo` 在 `start` JSON 中传递。
- 与历史 WS 独立；`sendCommand` 仍要求历史 WS 就绪（与现网一致）。

## Decisions

- 录音：`record` pcm16bits 16kHz mono，Binary 上行（不用插件内置 SpeechService，避免华为 AudioRecord 崩溃）。
- 默认引擎：`SpeechEngineStore` 按平台默认（Android `cloudAsr`，iOS `systemStt`）。
- UI：`voiceAsrWsClient.readyStream` 驱动「语音转写未连接」提示。

## Risks

- 弱网导致 `started`/`asr_final` 超时；已设超时与 `end` 收尾。
- 同 `deviceNo` 新连接踢旧连接：断线后需重连。
