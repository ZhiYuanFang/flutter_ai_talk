## ADDED Requirements

### Requirement: Listen chip MUST NOT show when landscape voice is paused

When `kPredictionLandscapeVoiceEnabled` is `false`, the smart prediction landscape UI MUST NOT render `_LandscapeVoiceListenChip` (or equivalent listen entry). Tap-to-wake / force-reset via the chip MUST NOT be reachable.

当 `kPredictionLandscapeVoiceEnabled` 为 `false` 时，预测横屏 UI MUST NOT 渲染监听 chip（或等价入口）；经 chip 的点按唤醒 / 强制复位 MUST NOT 可达。

#### Scenario: 暂停时无 chip

- **WHEN** 横屏语音编译期开关关闭
- **THEN** 预测横屏 MUST NOT 出现「说你好胖宝」类监听 chip
