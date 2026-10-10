## Why

云端 `/voice/asr/ws` 会因静音 VAD 在一次按住内多次下发 `asr_final`（段锁定）。客户端 `VoiceAsrWsClient` 用单一 Completer 把**第一次** final 当作整轮结果，导致停顿后续 partial 覆盖前文、松手却只保留前半段。需在客户端句段累积，并写入全局工程规范，避免后续实时翻译等复用同一通道时再犯。

## What Changes

- `VoiceAsrWsClient`：单次 utterance 内累积中途 `asr_final`；`onPartial` / `endUtterance` 暴露「已锁定段 + 当前 partial」全文。
- 整轮边界仍仅由 client `commit` / `end` / `cancel` 决定；**不**改云端静音分段能力。
- 将「静音 final ≠ 整轮结束」写入 `openspec/project.md`（语音 ASR 例外旁），约束后续 Feature（含实时翻译规划）。
- Spec 增量修正 `voice-asr-ws`：`asr_final` 为段锁定语义；`endUtterance` 须返回累积全文。
- **不**改 `/voice/chat/ws` 对话编排；**不**改成长/首页 UI 拼接逻辑（仍消费客户端给出的全文）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `voice-asr-ws`：明确多次 `asr_final` 为句段锁定；`VoiceAsrWsClient` MUST 累积；整轮结束 MUST 仅在 client commit 之后收束。

## Impact

- 代码：`app/lib/voice/voice_asr_ws_client.dart`（主）；经 `CloudAsrHomeSpeechRecognizer` 惠及首页与成长轨迹按住说话。
- 文档：`openspec/project.md`；可选 `app/README.md` 一句指向。
- 无服务端变更；无新 WS；无 Android 原生改动。
