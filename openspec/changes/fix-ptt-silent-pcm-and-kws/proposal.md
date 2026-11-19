## Why

真机日志显示：竖屏「去记录」PTT 已 `beginListen ok` / `hold step=listening`，但按住全程无 `pcm chunkAvgAbs`，松手空 `commit`；同进程横屏点 chip 有 PCM 且可对话。根因高度指向 **开麦后并行播 ding（MediaPlayer）弄脏 Vivo 上 AudioRecord**。另：横屏说「胖宝」无法唤醒、点 chip 可说话，说明 chat 麦正常而 **KWS 未在听或 `restoreWake` 失败**。`fix-portrait-ptt-hold-mic` 的门闩不足以修复零 PCM。

## What Changes

- 竖屏 PTT：**禁止在 `beginListen` 已开流后并行播 ding**；改为不播、或 ding 完全结束后再开麦（优先不播，避免焦点争用）。
- 竖屏 hold 期间须有可观测 PCM 诊断（已有 chunk 日志）；无有效能量时不得假装「听得见」。
- 横屏：对话/`finishTurn` 后 **MUST** 可靠 `restoreWake`；失败时 status 可读、点 chip 仍可用；排查 pause→resume 与双录音机争用。
- 保留既有 hold 上行保护门闩（`fix-portrait-ptt-hold-mic`），本变更不回滚。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-fab-hold-voice`：PTT 开听与本地 ding 的时序/可否并行；开听后 MUST 有上行 PCM。
- `prediction-landscape-voice`：横屏待唤醒态 MUST 恢复 KWS；点 chip 旁路不变。

## Impact

- App：`LandscapeVoiceController.startHold`（去 ding 或重排）、可选 `playAssetWav` 调用点；`_restoreWakeListening` / `_attachWakeListening` / chip 收尾。
- 与 `fix-portrait-ptt-hold-mic` 并存：门闩 + 本变更 PCM/KWS。
- Go：无协议变更。
