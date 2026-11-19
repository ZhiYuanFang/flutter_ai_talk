## Context

真机（Vivo）对照：

- 竖屏 PTT：`hold step=listening` → MediaPlayer ding → 数秒内无 `pcm chunkAvgAbs` → `commitUtterance`。
- 横屏 chip：`wake step=listening` → 有 PCM / `effectiveSpeech` → 对话正常。
- 横屏唤醒词无效、点 chip 有效 → KWS 路径与 chat 上行解耦；疑 `restoreWake` / resume 未挂上。

已落地的 `holdUplinkProtected` 不解释「零 PCM」。

## Goals / Non-Goals

**Goals:**

- 竖屏按住说话期间 chat PCM 上行可观测、可识别。
- 横屏说「胖宝」在待唤醒态可触发开听；点 chip 行为保持。
- 改动面小，可热重启验证。

**Non-Goals:**

- 不改 Go VAD / 协议。
- 不重做 KWS 模型或阈值标定（除非日志证明模型未加载）。
- 不以 APK 扫包验收。

## Decisions

### 1. 竖屏 PTT 默认不播 ding

- **选择**：`startHold` 成功 `beginListen` 后 **MUST NOT** `playAssetWav(ding)`。Haptic + pill「请说话…」已够反馈。
- **备选**：await ding 完成再 `beginListen`——多占 0.5–1s 按住窗口，且 ding 仍可能污染后续开麦。
- **备选**：换低延迟/低打扰播放器——成本高，本变更不做。
- 横屏唤醒 ding 时序保持现状（点 chip / 唤醒词路径）。

### 2. 无 PCM 时的诚实 UI（轻量）

- 若 hold 超过短窗（如 1.5s）仍 `!hasEffectiveSpeech` 且无 ASR 字幕：可选字幕「请靠近说话」；不阻塞 commit。
- 高优仍是先恢复 PCM；本项可作 tasks 可选项。

### 3. 横屏 restoreWake 加固

- **选择**：核对 chip/`finishTurn` 后必走 `_restoreWakeListening`；`resume` 失败必须 fallback `start`；失败写清 `statusCaption` + `[LandscapeVoice]/`/`[LandscapeKws]`。
- 竖屏 `activatePortraitPreconnect` 已 `wake.stop()`；回横屏 `activate` 必须重新 `_attachWakeListening`，不得假定旧 `_wake` 仍可用。
- 若日志显示 chat 麦未停尽导致 KWS `startStream` 失败：在 restore 前加强 `ensureMicStopped` 间隙（已有 gap，可按需略增）。

### 4. 与 hold 门闩的关系

- 保留 `setHoldUplinkProtected`；本变更不依赖、不删除。

## Risks / Trade-offs

- [去掉 PTT ding 与旧 spec「异步叮」字面冲突] → 更新 `prediction-fab-hold-voice` delta：竖屏 PTT MUST NOT 在开流后并行 ding；MAY 省略 ding。
- [restoreWake 仍失败] → 至少 chip 可用；status 提示点按；再查双 AudioRecorder。

## Migration Plan

- 热重启验证竖屏 PCM 日志与横屏唤醒。
- 回滚：恢复 PTT ding 调用；restore 逻辑按 git 回退。

## Open Questions

- 无（PTT 禁并行 ding + restoreWake 加固已足够开干）。
