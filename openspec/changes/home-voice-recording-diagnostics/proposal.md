## Why

联调云端语音转写时需确认本机实际上送的音频参数（格式、采样率、增益、时长）。主页已有响度柱面向用户反馈，但缺少**可读的录音技术读数**。需在语音圆左侧提供可选的诊断面板，且**仅云端 ASR 模式**有意义（PCM 16kHz 直采路径）。

## What Changes

- 设置页增加开关「显示录音数据」，**默认关闭**，持久化到 `SharedPreferences`。
- 开关开启且当前引擎为 **云端 ASR**、且 `_listening == true` 时，在主页底部输入区**语音圆左侧**显示：
  - 格式：`PCM16`（小端 int16，与 `RecordConfig` 一致）
  - 采样率：`16000 Hz`
  - 增益：**当前 PCM 块** `avgAbs` 与**本场会话累计** `avgAbs`（均显示）
  - 时长：自进入 `_listening` 起的秒数（一位小数）
- Vosk / 系统 STT 下**不显示**该面板（即使开关打开）。
- 与现有 `onLevel` / PCM 回调共用数据路径，不新增第二路麦克风；诊断区 `IgnorePointer`，不干扰按住/滑出取消手势。

## Capabilities

### New Capabilities

- `home-voice-recording-diagnostics`：云端聆听时的录音参数诊断 overlay + 设置开关。

### Modified Capabilities

- （无）根目录 `openspec/specs/` 尚无基线。

## Impact

- `app/lib/config/`（prefs 读写，如 `recording_diagnostics_store.dart`）
- `app/lib/ui/settings_screen.dart`
- `app/lib/ui/home_screen.dart`、新建 `home_voice_recording_stats.dart`（或等价）
- `app/lib/audio/pcm_level.dart`（扩展 `pcm16AvgAbs` 与会话累计）
- `app/lib/voice/voice_asr_ws_client.dart` / `cloud_asr_home_speech_recognizer.dart`（上报诊断统计，或经扩展回调）
