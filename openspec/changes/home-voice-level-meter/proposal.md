## Why

主页按住说话时，用户仅有圆盘文案与转写字幕，缺少**即时「正在听、听得清」**的非文字反馈。在连接就绪后开录阶段（`_listening`），需要以**多柱响度电平**可视化麦克风输入，强化可感知性；并与滑出取消态在视觉上联动。

## What Changes

- 仅在 `_listening == true` 时，于底部语音输入区**右上方**显示多柱（均衡器式）响度指示器。
- 响度来源为**真实麦克风电平**：云端 ASR / Vosk 从 PCM 流计算 RMS；系统 STT 使用 `speech_to_text` 的 `onSoundLevelChange`（真电平，非假动画）。
- 柱高随响度动态变化；颜色随响度渐变（静 → 有声 → 较响）；**攻击快、回落慢**以避免抖动。
- 当 `_slideToCancel == true` 时，电平柱配色与语音圆取消态一致，使用主题 **error** 色系（高度仍可随响度变化）。
- 松手、取消、或 `_listening` 结束即隐藏电平柱并重置电平状态。
- 扩展 `HomeSpeechRecognizer`（或等价回调）向 `HomeScreen` 提供归一化响度 `0..1`，不改动 `sendCommand` / WS 协议。

## Capabilities

### New Capabilities

- `home-voice-level-meter`：主页按住聆听期间的多柱响度可视化、引擎统一电平回调、取消态 error 色联动。

### Modified Capabilities

- （无）根目录 `openspec/specs/` 尚无基线；本变更以新增能力规格为主。

## Impact

- `app/lib/ui/home_screen.dart`（电平状态、右上方 `Stack` 子组件、与 `_slideToCancel` 联动）
- 新建 `app/lib/ui/home_voice_level_bars.dart`（或等价小组件）与 `app/lib/audio/pcm_level.dart`（PCM RMS 工具，可选）
- `app/lib/asr/home_speech_recognizer.dart` 及 `vosk_home_speech_recognizer.dart`、`voice_asr_ws_client.dart` / `cloud_asr_home_speech_recognizer.dart`、`system_stt_home_speech_recognizer.dart`
- 与 `home-voice-slide-cancel` 已实现的 `_slideToCancel` 行为协同，无协议变更
