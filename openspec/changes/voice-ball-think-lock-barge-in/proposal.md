## Why

预测语音（竖屏语音球与横屏芯片共用会话）在思考阶段会随系统超时熄屏；App 回前台时播放器可能把上一句 wav 再播一遍。需要思考常亮与回前台不重播。播放窗开口打断已改由 `tts-playback-no-interrupt` 收回，本变更不再废止「播放中不得打断」。

## What Changes

- 思考窗（已提交、尚未开播回复 TTS）MUST 保持屏幕常亮；思考结束（开播或本轮失败收口）MUST 释放该锁。横屏沉浸投屏既有常亮保持独立。
- 播放窗仍禁止开口或点按停 TTS（见 `tts-playback-no-interrupt`）。思考窗仍为唤醒词打断。
- 界面暂停后释放未播完音频、亮屏不补播，见 `voice-pause-release-playback`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `landscape-voice-barge-in-window`：新增思考窗屏幕常亮。播放窗打断不在本变更。界面暂停释放音频不在本变更。

## Impact

- `app/lib/providers/landscape_voice_provider.dart`：思考 Wakelock。
- `app/lib/voice/voice_chat_ws_client.dart`：播中能量检测与界面暂停释放不在本变更。
- `app/lib/ui/smart_prediction_screen.dart`：沉浸 Wakelock 与思考锁引用计数，避免互相误关。
- 无新 HTTP / WebSocket 协议；无 Android 原生工程变更。
