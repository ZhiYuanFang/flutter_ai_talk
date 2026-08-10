## ADDED Requirements

### Requirement: Feeding page MUST hide input mode dock and use buttons only

The feeding `HomeScreen` MUST NOT render the home input mode dock (`HomeInputModeDock` or equivalent) for switching voice/text/buttons. The feeding input channel MUST be locked to event-buttons mode. The client MUST ignore any previously persisted voice/text channel when presenting the feeding page. Companion chat input modes MUST remain available and unchanged by this requirement.

喂养页 **不得** 展示输入模式切换 dock；输入 **必须** 锁定为事件按钮模式，并 **必须** 忽略历史语音/文字 channel 恢复。陪伴页输入模式 **不受** 本需求影响。

#### Scenario: 喂养页无模式切换器

- **WHEN** 用户打开喂养页
- **THEN** UI MUST NOT 展示 `HomeInputModeDock`（或等价语音/按钮切换浮控）
- **AND** MUST 展示事件按钮记录能力

#### Scenario: 历史语音偏好不恢复

- **WHEN** 本地曾持久化为语音输入 channel，用户进入喂养页
- **THEN** 喂养页 MUST 仍以事件按钮模式呈现
- **AND** MUST NOT 自动展示喂养语音球作为主输入

#### Scenario: 陪伴语音仍可用

- **WHEN** 用户从预测 tip 等入口 push 进入陪伴页且非 Web
- **THEN** 陪伴页 MUST 仍可切换/使用既有语音输入能力（不受喂养 dock 隐藏影响）
