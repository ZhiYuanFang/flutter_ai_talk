## MODIFIED Requirements

### Requirement: Next-3-hours card SHALL show AI分析 entry and full body text

When the next-3-hours timeline block is shown on the smart prediction page, the client SHALL render a rounded-background control labeled 「AI分析」 on the trailing side of the title row, and MUST show the timeline body in full without expand/collapse controls. Tapping 「AI分析」 MUST open the AI analysis page and MUST NOT navigate to the feeding pager. The card body, empty areas, and the fixed title text「接下来3小时」MUST NOT navigate to the feeding pager（整卡不可点进喂养）. When entitlement settle is ready, the title row MUST also expose the predict-tier suffix per `predict-capability-tier-wall`, and ONLY that suffix（besides 「AI分析」）MAY be tappable on the card. 当展示「接下来3小时」块时，标题行右侧 **必须** 有圆角「AI分析」；正文 **必须** 全量展示且无展开/收起；点「AI分析」进 AI 分析页且 **不得** 进喂养；整卡/正文/「接下来3小时」六字 **不得** 进喂养；settle ready 时版本文案热区按三档墙规格，且卡上除 AI分析与版本文案外 **不得** 另设点击导航。

#### Scenario: 有三小时则始终显示 AI分析

- **WHEN** 智能预测页正在展示「接下来3小时」时间线块
- **THEN** 标题行右侧 MUST 显示「AI分析」按钮
- **AND** MUST NOT 显示「展开」或「收起」

#### Scenario: AI分析不进喂养

- **WHEN** 用户点击「AI分析」
- **THEN** 客户端 MUST 打开 AI 分析页
- **AND** MUST NOT 仅因此请求切换到喂养主页

#### Scenario: 整卡与正文不进喂养

- **WHEN** 用户点击三小时卡正文或非 AI分析/非版本文案区域
- **THEN** 客户端 MUST NOT 因此切换到喂养主页
