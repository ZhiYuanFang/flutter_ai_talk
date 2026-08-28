## Why

横屏语音偶发「回复播到一半声停 → 答案字幕一直不消 → 久不进入请说话 → 只能再唤醒」。根因是话轮收口绑在 `audio_end` 之后 **await `onPlayerComplete`** 才发 `VoiceChatTurnEnded`；播放器中途停播却不触发 complete 时，前端可卡死长达约 2 分钟，期间服务端可能已 `waitEndAfterCommit`，续听/`finish_talk` 契约无法执行。产品选择先封死这条「结束语境没收口」路径（探索结论 A）。

## What Changes

- `VoiceChatWsClient`：TTS 播放完成判定 MUST 带 **与 PCM 时长相关的超时上限**（远短于现网 2 分钟）；超时、播放失败或状态异常结束后 MUST 仍按已解析的 `finish_talk` 发出 `VoiceChatTurnEnded`，不得无限挂起。
- `audio_chunk` 与 `audio_end` 处理 MUST **串行**（同队列/await），避免 `audio_end` 抢先 `takeBytes` 导致半包开播（加重「播不全」）。
- 收到 `audio_end` 后，在非 `_ttsDiscard`（非 barge-in 主动丢弃）路径上，MUST **保证一次话轮收口事件**（`TurnEnded`），使编排层清字幕并走续听或回唤醒。
- Debug：记录 play complete / timeout / seal TurnEnded 的 `finish_talk` 来源；经 `AppDebugLog.landscapeVoice`。
- **不**改变 `finish_talk` 语义与 `end`→`start` 传输契约；**不**把 barge-in `ttsDiscard` 成功打断改成误发 TurnEnded（打断成功仍由 barge-in 编排接管）。

## Capabilities

### New Capabilities

- `landscape-voice-tts-turn-seal`：横屏 chat TTS 播完/超时后必须封口话轮（`TurnEnded`），以及 chunk/`audio_end` 串行，防止声停字幕假死。

### Modified Capabilities

- （无独立基线文件夹可改；与进行中 `voice-chat-ws-round-contract` 的 `finish_talk`/`TurnEnded` 编排衔接，本变更只补 TTS 收口缺口。）

## Impact

- 代码：`app/lib/voice/voice_chat_ws_client.dart`（播放超时、串行队列、seal）；必要时 `landscape_voice_provider.dart` 仅消费既有 `TurnEnded`（无行为分叉则不动）。
- 行为：声停或播完异常时，短时内清字幕并按 `finish_talk` 续听或回唤醒，无需强制再唤醒。
- 约束：仍走既有 chat WS；无裸 `debugPrint`；不新建 `**/test/**`。
