## Context

竖屏语音球与横屏芯片共用 `LandscapeVoiceController` + `VoiceChatWsClient`。思考窗可唤醒词 barge-in；`_onBeforeTtsPlay` 在回复 TTS 开播前 pause KWS 并禁止播中打断。有效音 `effectiveChunkAvgAbs`（130）只在开听上行 PCM 上累计，用来取消 5 秒无声退出。`WakelockPlus` 仅横屏沉浸投屏持有。`AudioPlayer` 无生命周期处理，回前台可能重播上一句 wav。

## Goals / Non-Goals

**Goals:**

- 思考窗屏幕常亮，结束即释放。
- `paused` 停播丢弃；`resumed` 不重播。

**Non-Goals:**

- 播放窗开口或点按打断（由 `tts-playback-no-interrupt` 明确禁止，播中不得再开麦）。
- 回声消除 / 改服务端协议。
- 思考窗改为任意声音打断（仍用唤醒词）。

## Decisions

### D1：思考锁与沉浸锁引用计数

- **选择**：思考进入 `WakelockPlus.enable`，离开 disable；若沉浸投屏仍持有锁，disable 不得关掉投屏锁（共享计数或「任一原因仍需要则保持 enable」）。
- **理由**：两处都用同一插件，互相 `disable` 会误关。

### D2：后台停播

- **选择**：`AppLifecycleState.paused`（及 `inactive` 若平台会停声）调用 `stopTts`（`_ttsDiscard` + `stop`）。`resumed` MUST NOT `play` 上一文件。若当时正在等播完，按 discard 收口（不补「正常播完」），编排回到唤醒或按已解析 `finish_talk` 的既有非播完路径，且不得再播该 PCM。
- **理由**：`just_audio` 默认可能在会话恢复时重播。

## Risks / Trade-offs

- [Wakelock 泄漏] → 思考结束、deactivate、dispose 都必须释放思考原因。

## Migration Plan

- 纯客户端。回滚：恢复播中 disarm 与无生命周期停播即可。

## Open Questions

- （无）思考常亮与 resume 不重播已确认。播放中打断已撤回。
