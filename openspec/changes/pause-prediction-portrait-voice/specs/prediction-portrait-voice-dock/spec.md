## MODIFIED Requirements

### Requirement: Portrait prediction voice MAY be gated off without landscape impact

When `kPredictionPortraitVoiceEnabled` (or equivalent compile-time flag) is `false`, the smart prediction page in **portrait** MUST NOT show any prediction-voice entry (EdgeDock ball, listen chip, subtitle toast, or placeholder), and MUST NOT activate the prediction voice session / request microphone solely because the prediction page is visible in portrait. When the flag is `true`, portrait voice MUST follow the existing EdgeDockShell portrait voice dock requirements. **Landscape** prediction voice (fixed listen chip and session lifecycle) MUST remain available regardless of this portrait flag.

当竖屏语音开关为 `false` 时，智能预测**竖屏** **必须 NOT** 展示任何预测语音入口，且 **必须 NOT** 仅因竖屏预测可见而 activate 会话或请求麦克风。开关为 `true` 时竖屏 **必须** 遵循既有贴边球契约。**横屏** 预测语音 **必须** 不受该竖屏开关关闭。

#### Scenario: 竖屏暂停无入口

- **WHEN** `kPredictionPortraitVoiceEnabled` 为 false 且用户在智能预测页竖屏
- **THEN** UI MUST NOT 展示语音贴边球、监听 chip、语音字幕 toast 或「暂未开放」类占位入口
- **AND** 客户端 MUST NOT 因竖屏预测页可见而 activate 预测语音会话或弹出麦克风权限

#### Scenario: 横屏仍开放

- **WHEN** `kPredictionPortraitVoiceEnabled` 为 false 且用户在智能预测页横屏
- **THEN** UI MUST 仍展示横屏固定监听 chip（语音可用时）
- **AND** 预测语音生命周期 MUST 仍可按横屏∩预测可见规则 activate

#### Scenario: 开关翻回恢复竖屏球

- **WHEN** `kPredictionPortraitVoiceEnabled` 为 true 且用户在智能预测页竖屏且语音可用
- **THEN** UI MUST 恢复 EdgeDockShell 竖屏语音球（及既有 peek/engaged/字幕契约）
