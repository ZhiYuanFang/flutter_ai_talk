## Context

竖屏语音球与横屏芯片共用 `LandscapeVoiceController` + `VoiceChatWsClient`。思考窗可唤醒词 barge-in；`_onBeforeTtsPlay` 在回复 TTS 开播前 pause KWS 并禁止播中打断。有效音 `effectiveChunkAvgAbs`（130）只在开听上行 PCM 上累计，用来取消 5 秒无声退出。`WakelockPlus` 仅横屏沉浸投屏持有。`AudioPlayer` 无生命周期处理，回前台可能重播上一句 wav。

## Goals / Non-Goals

**Goals:**

- 思考窗屏幕常亮，结束即释放。

**Non-Goals:**

- 界面暂停释放音频、亮屏不补播（由 `voice-pause-release-playback` 约束）。
- 播放窗开口或点按打断（由 `tts-playback-no-interrupt` 明确禁止，播中不得再开麦）。
- 回声消除 / 改服务端协议。
- 思考窗改为任意声音打断（仍用唤醒词）。

## Decisions

### D1：思考锁与沉浸锁引用计数

- **选择**：思考进入 `WakelockPlus.enable`，离开 disable；若沉浸投屏仍持有锁，disable 不得关掉投屏锁（共享计数或「任一原因仍需要则保持 enable」）。
- **理由**：两处都用同一插件，互相 `disable` 会误关。

## Risks / Trade-offs

- [Wakelock 泄漏] → 思考结束、deactivate、dispose 都必须释放思考原因。

## Migration Plan

- 纯客户端。回滚：恢复播中 disarm 与无生命周期停播即可。

## Open Questions

- （无）思考常亮与 resume 不重播已确认。播放中打断已撤回。
