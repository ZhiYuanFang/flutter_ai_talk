## Why

`voice-ball-think-lock-barge-in` 在回复 TTS 播放中再开一路麦克风做开口打断，Android 上 `AudioRecord` 会停掉正在播的 `MediaPlayer`，喇叭回灌也会误触发停播，结果是回复音频放不出来。播放窗改回不允许打断，让回复能播完。

## What Changes

- 回复 TTS 播放期间 MUST NOT 为打断启动本地录音，MUST NOT 因开口、唤醒词或点按聆听入口（横屏芯片 / 竖屏语音球）调用 `stopTts`。
- 思考窗仍可用唤醒词打断；思考常亮与沉浸投屏引用计数保持 `voice-ball-think-lock-barge-in` 已实现行为。
- 进入后台仍停播并丢弃，回到前台仍不重播上一句。
- 未归档变更 `voice-ball-think-lock-barge-in` 中「播中开口 / 播中点按停 TTS」的规格增量须收回，避免收版时与本变更互相覆盖。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `landscape-voice-barge-in-window`：播放窗禁止开口能量打断与点按停播，并禁止播中为打断占麦；思考窗唤醒词打断不变。

## Impact

- `app/lib/voice/voice_chat_ws_client.dart`：去掉播中能量检测与 `onTtsSpeechBarge`。
- `app/lib/providers/landscape_voice_provider.dart`：播中忽略唤醒与芯片/语音球点按。
- `openspec/changes/voice-ball-think-lock-barge-in/`：收回与本变更冲突的播放窗规格，保留思考常亮与后台停播。
- 无新 HTTP / WebSocket 协议；无 Android 原生工程变更。
