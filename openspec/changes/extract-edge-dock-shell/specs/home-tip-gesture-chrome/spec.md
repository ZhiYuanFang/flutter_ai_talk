## MODIFIED Requirements

### Requirement: Pointer on tip bounds MUST block PageView swipe

While a pointer is down within the tip expanded card bounds or within the edge-dock shell hittable target used for tip ball states, the client MUST prevent home PageView horizontal page changes until release/cancel. tip 展开卡或 tip 所用 EdgeDock 壳热区指针按下期间 **必须** 禁止 PageView 横滑直至抬起/取消。

#### Scenario: 在 tip 壳球上横滑不切页

- **WHEN** tip 为 peek/floating 球态且用户在壳热区内横滑
- **THEN** PageView MUST NOT 切页

#### Scenario: tip 卡外仍可滑页

- **WHEN** 用户在 tip 卡与壳热区外横滑
- **THEN** PageView MUST 仍可切页
