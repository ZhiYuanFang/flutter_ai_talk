## Why

预测语音回复还在播时熄屏再亮，同一句会接着放。`voice-ball-think-lock-barge-in` 只在 `paused` / `hidden` 时 `stop()`，播放器源还在；亮屏后 Android 播放器会把这段续上。界面暂停后应直接释放这段音频，回到前台不补播。

## What Changes

- 回复 TTS 或同一播放器上的本地提示在界面进入 `inactive`（熄屏）、`hidden` 或 `paused` 时，客户端 MUST 停止并释放当前播放，丢弃未播完缓冲。
- 回到 `resumed` MUST NOT 播放该句，并 MUST 再次停止/释放，避免插件把上一句续上。
- 正在等播完的话轮按丢弃收口，MUST NOT 补发成功播完的 `VoiceChatTurnEnded`。
- 未归档变更 `voice-ball-think-lock-barge-in` 里较弱的「仅 stop」规格改由本变更取代，避免收版写回续播窗口。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `landscape-voice-tts-turn-seal`：界面暂停（含熄屏 `inactive`）MUST 释放当前音频；回到前台 MUST NOT 补播。

## Impact

- `app/lib/voice/voice_chat_ws_client.dart`：生命周期停播改为 stop + release，并覆盖 `inactive` 与 `resumed` 防续播。
- `openspec/changes/voice-ball-think-lock-barge-in/`：收回较弱的 pause 规格。
- 无新 HTTP / WebSocket 协议；无 Android 原生工程变更。
