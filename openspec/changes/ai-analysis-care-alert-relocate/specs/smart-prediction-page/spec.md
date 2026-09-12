## ADDED Requirements

### Requirement: Next-3-hours card SHALL show AI分析 entry and full body text

When the next-3-hours timeline block is shown on the smart prediction page, the client SHALL render a rounded-background control labeled 「AI分析」 on the trailing side of the title row, and MUST show the timeline body in full without expand/collapse controls. Tapping 「AI分析」 MUST open the AI analysis page and MUST NOT navigate to the feeding pager. Tapping the remainder of the card MUST still open the feeding pager as before. 当展示「接下来3小时」块时，标题行右侧 **必须** 有圆角「AI分析」；正文 **必须** 全量展示且无展开/收起；点「AI分析」进 AI 分析页且 **不得** 进喂养；点卡片其余区域仍进喂养。

#### Scenario: 有三小时则始终显示 AI分析

- **WHEN** 智能预测页正在展示「接下来3小时」时间线块
- **THEN** 标题行右侧 MUST 显示「AI分析」按钮
- **AND** MUST NOT 显示「展开」或「收起」

#### Scenario: AI分析与喂养手势分离

- **WHEN** 用户点击「AI分析」
- **THEN** 客户端 MUST 打开 AI 分析页
- **AND** MUST NOT 仅因此请求切换到喂养主页

#### Scenario: 正文全量

- **WHEN** 三小时时间线正文超过两行
- **THEN** UI MUST 仍完整展示全部正文
- **AND** MUST NOT 以折叠行数隐藏尾部

## MODIFIED Requirements

### Requirement: Smart prediction page SHALL NOT show the care-alert card above the timeline

The smart prediction page MUST NOT place a「值得留意」care-alert card (marquee or eligibility/unlock shell) above the next-3-hours timeline for bound warm states. Auth-guest swipe guide chrome MAY remain where previously substituted for that slot. Relative ordering MUST be: optional guest guide (if any), then next-3-hours (when present), then event cards—without an intervening care-alert panel. 已绑定热态下，智能预测页在三小时时间线之上 **不得** 再放值得留意卡；游客滑动引导可保留；顺序为可选引导 → 三小时（若有）→ 事件卡，中间无留意面板。

#### Scenario: 热态无留意介于三小时之上

- **WHEN** 用户已登录已绑定且非 demo 冷态骨架
- **AND** 页面展示「接下来3小时」
- **THEN** 「接下来3小时」之上 MUST NOT 出现「值得留意」卡片
