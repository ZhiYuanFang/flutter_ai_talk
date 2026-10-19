## Context

`VoiceChatWsClient` 在 `paused` / `hidden` 且 `_ttsPlaying` 时调用 `stopTts()`，只对 `AudioPlayer.stop()`。短提示音把同一播放器设成 `PlayerMode.mediaPlayer`。思考常亮在回复开播时释放，熄屏可以发生在 TTS 播放中。Android 在界面 pause 时先暂停 MediaPlayer，回到前台再 resume。`stop()` 经常盖不住这次续播。`inactive`（熄屏常见第一步）目前直接忽略。

## Goals / Non-Goals

**Goals:**

- 界面暂停或熄屏时释放正在播的这一段（回复 TTS 与同一播放器上的本地提示）。
- 回到前台不补播，并再挡一次插件续播。
- 未播完的话轮按 discard 收口，不补成功 `VoiceChatTurnEnded`。

**Non-Goals:**

- 播中开口打断（已由 `tts-playback-no-interrupt` 禁止）。
- 思考常亮、沉浸投屏锁。
- 改服务端协议或换播放器库。

## Decisions

### D1：pause 时 stop 并 release

- **选择**：`inactive`、`hidden`、`paused` 都丢掉当前段：`_ttsDiscard`、清缓冲、`stop()` 后 `release()`，并解开等播完的 Future。不再只在 `_ttsPlaying` 为真时才停；只要播放器可能还握着上一源就释放。
- **理由**：熄屏往往先到 `inactive`。只 `stop()` 时，亮屏后插件会 resume 同一 MediaPlayer。
- **备选否决**：播放中重新打开思考常亮阻止熄屏 — 用户要的是暂停后释放音频，不是禁止熄屏。

### D2：resumed 只释放，不 play

- **选择**：`resumed` MUST NOT 调用 `play`。再 `stop` / `release` 一次。丢弃收口仍走已有 `onTtsStoppedByLifecycle`（不补成功播完）。
- **理由**：插件的 onResume 可能发生在我们第一次 stop 之后。

### D3：规格只留在本变更

- **选择**：从 `voice-ball-think-lock-barge-in` 的 `landscape-voice-tts-turn-seal` delta 去掉较弱的 pause 要求，避免两份 ADDED 同题收版冲突。
- **理由**：基线尚无该 Requirement；较弱版本与本变更不能同时合并。

## Risks / Trade-offs

- [release 后下一次「我在」要重新配置播放器] → `play` / `playAssetWav` 前照旧 `setPlayerMode` / `setReleaseMode`。
- [inactive 误伤短暂切后台动画] → 只释放正在播的段，不结束整段会话以外的状态；已有 discard 收口。

## Migration Plan

- 纯客户端。回滚：恢复仅 `paused`/`hidden` 的 `stop()`。

## Open Questions

- （无）界面 pause 后释放当前音频、不补播已确认。
