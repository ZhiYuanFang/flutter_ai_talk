## Why

预测横屏唤醒后对话常卡在左下角「我在听…」，用户无法判断 `/voice/chat/ws` 是否已连、本轮是否已真正开麦上送；现有 chip 仅用文案与 mic 图标，连接态不可见。需要把 WS 连接与「本轮在听」做成话筒旁指示，并修复唤醒后卡在「我在听…」无法进入「请说话…」的启动链路。

## What Changes

- 左下监听 chip：话筒旁红/绿点三态——未连接红；已连接待唤醒绿点亮、话筒不高亮；已连接且本轮在听绿点 + 话筒高亮。
- 将 `VoiceChatWsClient.isReady` / `readyStream` 与本轮 `isListening` 暴露到 `LandscapeVoiceUiState` 并驱动 UI。
- 修复唤醒后停在「我在听…」：细化启动阶段文案；`pause` / `startStream`（及必要衔接）加超时与失败恢复；失败清 `_turnBusy`、resume KWS、可读短因。
- 增加 `[LandscapeVoice]` Debug 日志（三联白名单），覆盖连接、唤醒启动各步、开麦失败。

## Capabilities

### New Capabilities

- `landscape-voice-listen-chip`: 横屏左下监听入口的 WS 连接指示与本轮聆听高亮，以及唤醒后开听启动的可观测/失败恢复行为。

### Modified Capabilities

- （无）基线尚未合并 `prediction-landscape-voice` 的芯片细则；本变更以新能力规格约束指示灯与开听启动，不修改已归档基线其它 Requirement。

## Impact

- 代码：`landscape_voice_provider.dart`、`smart_prediction_screen.dart`（`_LandscapeVoiceListenChip`）、`voice_chat_ws_client.dart`、`landscape_wake_word.dart`（pause 超时若需要）、`app_debug_log.dart` + `logcat_api_http.ps1` + `app/README.md`。
- 无新依赖；无 Android Manifest / R8 预期变更。
