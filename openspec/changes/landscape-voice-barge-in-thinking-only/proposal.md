## Why

预测页语音在 `interrupt_commit` 后立刻 arm barge-in（开 KWS 麦），与随后 TTS 播放并行，Android 上常导致 `MediaPlayer.pause`，听感「回复播不全」。产品已定：**思考阶段可唤醒词打断，TTS 播放阶段禁止打断**，以单一麦所有权避免播录抢焦点，且不引入套娃式特例链。

## What Changes

- Thinking（`interrupt_commit` 之后、TTS 开播之前）：MAY/MUST 保持现有 barge-in arm（KWS resume），允许再说唤醒词打断。
- Speaking（`audio_end` 开始播 TTS 之前）：MUST pause/disarm KWS，禁止 barge-in 开麦；唤醒检测 MUST NOT 在 Speaking 触发 `_onBargeInWake`。
- TTS 播完 `TurnEnded` 之后：按既有 `finish_talk` 续听或回唤醒；续听路径 MUST NOT 在播中重新 arm KWS。
- 芯片在 Speaking 期间：本变更 **不要求** 播中可打断（与「播放禁止打断」一致）；Thinking / 假死复位行为保持可点。
- 与 `landscape-voice-tts-turn-seal` 正交：后者管 complete 假死；本变更管 **何时占麦**。
- Debug：`bargeIn pause/disarm reason=tts_start`（或等价）经 `AppDebugLog.landscapeVoice`。

## Capabilities

### New Capabilities

- `landscape-voice-barge-in-window`：横/竖屏预测语音 barge-in 仅在思考窗开放，TTS 播放窗关闭。

### Modified Capabilities

- （无独立基线文件夹；与进行中 `landscape-voice-wake-barge-in` / 多轮契约衔接，本变更只收窄 arm 时机。）

## Impact

- 代码：主要 `landscape_voice_provider.dart`（arm/disarm 时序）；必要时 `voice_chat_ws_client.dart` 暴露「即将播 TTS」回调；`LandscapeWakeWord.pause`。
- 行为：思考中仍可喊打断；播回复时唤醒词无效，播完再续听/回唤醒；消除 KWS 开麦 pause TTS。
- 约束：不改 Go；不新建测试；无裸 print。
