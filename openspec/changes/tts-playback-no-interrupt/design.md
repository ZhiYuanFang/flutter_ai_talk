## Context

基线 `landscape-voice-barge-in-window` 规定：思考窗可用唤醒词打断；回复 TTS 开播前必须放开 KWS；播放中唤醒词与聆听芯片都不得 `stopTts`。未归档变更 `voice-ball-think-lock-barge-in` 已在代码里改成播中开口打断：`play()` 之后用同一只 `AudioRecorder`（`voiceRecognition` + AGC、无回声消除）`startStream`。真机上录音会话会停掉 `MediaPlayer`，喇叭回灌也会在约 400ms 后误触发 `stopTts`，回复音频放不出来。思考常亮与进后台停播是该变更里仍要保留的部分。

## Goals / Non-Goals

**Goals:**

- 播放窗不再为打断占麦，回复 TTS 能播完。
- 播放中开口、唤醒词、点按横屏芯片或竖屏语音球都不停播。
- 思考窗唤醒词打断、思考常亮、进后台停播且 resume 不重播保持不变。
- 收回 `voice-ball-think-lock-barge-in` 里与播放窗打断冲突的规格，避免两份变更收版互相覆盖。

**Non-Goals:**

- 回声消除、改播放器通路、或换一套「播中能听麦又不抢焦点」的实现。
- 改思考窗能量打断。
- 去掉思考常亮或生命周期停播。

## Decisions

### D1：播放窗关掉能量检测，而不是调门槛

- **选择**：删除播中 `_startTtsBargeMonitor` / `onTtsSpeechBarge`。`_onBeforeTtsPlay` 只 pause KWS，不再开第二路录音。
- **理由**：放不出声音的直接原因是播中 `AudioRecord` 与 `MediaPlayer` 抢会话。抬高 260 门槛解决不了播放器被停。
- **备选否决**：低延迟播放器或另一音源继续开口打断 — 用户已改为播放中不允许打断。

### D2：播中点按恢复忽略

- **选择**：`_ttsPlaybackActive` 时，唤醒检测与 `onListenChipTap`（横屏芯片与竖屏语音球同一入口）直接返回，不调用 `stopTts`。思考窗与「请说话」假死复位仍走原路径。
- **理由**：点按停播与开口停播是同一产品决定，只关麦、留点按仍会把正在播的回复停掉。

### D3：先改未归档变更的规格，再改代码

- **选择**：从 `voice-ball-think-lock-barge-in` 的 delta 中去掉「废止播放窗禁止 barge-in」以及「开口打断 / 播中点按停 TTS」两条 ADDED；保留思考常亮。本变更再 MODIFIED 基线播放窗要求，写明播中不得为打断占麦，点按范围含竖屏语音球。
- **理由**：两份 delta 同时收版时，先 REMOVED 再被后一份加回的打断要求会把行为写反。

## Risks / Trade-offs

- [播放中不能开口或点球停播] → 用户已接受；思考窗仍可唤醒词打断。
- [只删检测、生命周期误停播] → `paused`/`hidden` 停播保持，且仅在 `_ttsPlaying` 时触发，不在开播瞬间占麦。

## Migration Plan

- 纯客户端。回滚即恢复播中能量检测与点按停播。

## Open Questions

- （无）播放中不允许打断已确认。
