## Why

主页语音输入仅支持在语音圆上松手结束并可能发送指令；手指滑出按钮仍会继续录音并在松手时 `sendCommand`，易误发。需支持**按住后滑出语音圆取消**、**滑回圆内恢复发送**，取消区以 **132px 语音圆** 为准（非整块底部区域）。

## What Changes

- 按住说话期间跟踪指针位置：在圆外为「取消态」，在圆内为「发送态」；**滑回圆内可恢复**发送态。
- 取消态 UI：文案「松开取消」、视觉强调（如边框/色为 error 或 outline）。
- 松手：取消态 → `cancelSession`，不调用 `sendCommand`；发送态 → 现有 `_onVoiceEnd` 逻辑。
- 底部输入区在按住期间扩大指针跟踪范围（避免手指移远后丢失 move），但**是否在圆外**仍以语音圆 `RenderBox` 判定。
- 适用于云端 / Vosk / 系统 STT（统一走 `HomeSpeechRecognizer.cancelSession`）。

## Capabilities

### New Capabilities

- `home-voice-slide-cancel`：滑出语音圆取消、滑回恢复、松手分流。

### Modified Capabilities

- `home-input-history-sse`：补充按住说话期间的取消手势与不误发场景。

## Impact

- `app/lib/ui/home_screen.dart`
- 可选小幅 OpenSpec delta 于 `home-input-history-sse`
