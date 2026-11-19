## Context

竖屏「去记录」PTT（`predict-fab-hold-voice`）约定：松手为唯一业务 `commit`；按住期间服务端 `interrupt_commit` 不得驱动业务收口。实现上编排层已 `if (_holdActive) return`，但 `VoiceChatWsClient` 在收到 `interrupt_commit` / `asr_no_result` 时仍无条件 `_stopMicOnly()`。真机表现：pill 显示「请说话…」、无实时 ASR、松手后像没说话；横屏依赖抢先 commit，行为正常。

## Goals / Non-Goals

**Goals:**

- 竖屏 hold 期间 PCM 上行不被服务端抢先帧打断。
- 松手 / 取消 / teardown 仍为停麦点；横屏 interrupt_commit 停麦行为不变。
- 聆听 UI 与真实 `isListening` 一致；关键路径有 `[LandscapeVoice]` 日志。

**Non-Goals:**

- 不改 Go 协议或关闭服务端 VAD。
- 不改横屏 KWS / TTS 主路径。
- 不重做 FAB 布局（单行自适应已在先前修补）。
- 不以 APK 扫包作为本变更验收。

## Decisions

### 1. hold 门闩放在 VoiceChatWsClient

- **选择**：增加显式门闩（如 `suppressServerMicStop` / `holdUplinkProtected`），由 `LandscapeVoiceController.startHold` 置真、`endHold` / teardown 清假。`interrupt_commit` 与 `asr_no_result` 在门闩开启时：仍可向上游 emit 事件供编排记录，但 **MUST NOT** `_stopMicOnly`。
- **备选**：仅在编排层收到事件后立刻 `beginListen` 续麦——存在空窗与竞态，且 asr_no_result 已停麦。
- **备选**：改服务端 hold 模式不下发 interrupt——跨端改动大，本变更不做。

### 2. 编排层继续忽略业务收口，并校正 UI

- **选择**：保持 `_holdActive` 时忽略 interrupt 的 barge-in / 思考武装；对 `asr_no_result` 在按住期间不展示「没听清」（避免误导），松手后若仍无有效音再提示。
- 若门闩因异常未开而麦已停：检测到 `!chat.isListening && _holdActive` 时更新字幕/ pill，禁止继续「请说话…」。

### 3. ding 与开麦顺序

- **选择**：保持「先 `beginListen` 再异步 ding」（已缩短未开麦窗口）；若真机仍有焦点争用，可改为 hold 不播 ding（横屏保留）。本变更高优是停麦门闩。

### 4. 日志

- hold 置门闩、收到被抑制的 interrupt/asr_no_result、松手 commit 均打 `[LandscapeVoice]`；早退路径（inactive / micDenied）补日志，避免再现「UI 亮了但无 tag」。

## Risks / Trade-offs

- [服务端仍按静音切段] → 客户端忽略停麦后可能在同一 session 上继续喂 PCM；松手再 client `commit`。若服务端已本地收口导致后续 PCM 被丢，需观察；缓解：松手前若 `!isListening` 则重 `beginListen` 再短窗或直接提示重说。
- [横屏误开新门闩] → 门闩仅 `startHold`/`endHold` 生命周期，横屏唤醒路径不得置真。
- [门闩忘记清除] → `endHold` / `_tearDown` / `deactivate` 必须清；用 try/finally 或与 `_holdWanted` 同清。

## Migration Plan

- 热重启即可验证；无数据迁移。
- 回滚：恢复 `interrupt_commit`/`asr_no_result` 无条件停麦。

## Open Questions

- 无（按住抑停麦 + 松手 commit 已足够落地）。
