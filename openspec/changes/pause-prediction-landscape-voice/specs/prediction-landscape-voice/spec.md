## ADDED Requirements

### Requirement: Landscape prediction voice SHALL be gateable by compile-time flag

When `kPredictionLandscapeVoiceEnabled` is `false`, the smart prediction page in landscape MUST NOT mount the landscape voice lifecycle binder, MUST NOT show the listen chip or voice subtitle toast, and MUST NOT call `LandscapeVoiceController.activate` (including via `syncLandscapeVoiceLifecycle`) for prediction-visible landscape. The client MUST NOT request microphone permission solely for landscape prediction voice while the flag is off. When the flag is `true`, existing landscape wake / chat / chip behavior MUST remain available subject to platform constraints (non-web Android/iOS).

当 `kPredictionLandscapeVoiceEnabled` 为 `false` 时，智能预测页横屏 MUST NOT 挂载语音生命周期 binder，MUST NOT 展示监听 chip 或语音字幕 toast，MUST NOT 对预测可见横屏调用 `activate`（含经 `syncLandscapeVoiceLifecycle`）；MUST NOT 仅因横屏预测语音在 flag 关闭时请求麦克风。flag 为 `true` 时，既有横屏唤醒/会话/chip 行为 MUST 在平台约束下仍可用。

#### Scenario: flag 关闭无横屏语音表面

- **WHEN** `kPredictionLandscapeVoiceEnabled == false` 且用户在预测页横屏
- **THEN** MUST NOT 展示左下监听 chip
- **AND** MUST NOT 展示语音字幕 toast
- **AND** MUST NOT 因进入该横屏预测会话而 activate KWS / chat

#### Scenario: flag 开启恢复横屏语音

- **WHEN** `kPredictionLandscapeVoiceEnabled == true` 且非 Web 的 Android/iOS 预测页横屏可见
- **THEN** 客户端 MAY 按既有契约 activate 并展示监听 chip
