## MODIFIED Requirements

### Requirement: Next-3-hours card SHALL show AI分析 entry and full body text

When the next-3-hours timeline block is shown on the smart prediction page, the client MUST show the timeline body in full without expand/collapse controls. The title row MUST NOT render an「AI分析」control and MUST NOT navigate to a retired AI analysis page. The card body, empty areas, and the fixed title text「接下来3小时」MUST NOT navigate to the feeding pager. When Free/Pro tier chrome is ready, the title row MUST expose the predict-tier suffix per `predict-free-pro-chrome`, and ONLY that suffix MAY be tappable on the card for opening the two-tier wall. 当展示「接下来3小时」块时，正文 **必须** 全量展示且无展开/收起；**不得** 显示「AI分析」或进入已删 AI 分析页；整卡/正文/「接下来3小时」六字 **不得** 进喂养；档位就绪时版本文案热区按免费/Pro 两档规格，且卡上除版本文案外 **不得** 另设点击导航。

#### Scenario: 有三小时则无 AI分析

- **WHEN** 智能预测页正在展示「接下来3小时」时间线块
- **THEN** 标题行 MUST NOT 显示「AI分析」按钮
- **AND** MUST NOT 显示「展开」或「收起」

#### Scenario: 整卡与正文不进喂养

- **WHEN** 用户点击三小时卡正文或非版本文案区域
- **THEN** 客户端 MUST NOT 因此切换到喂养主页

#### Scenario: 版本文案可开两档墙

- **WHEN** Free/Pro 档位 chrome 已就绪且用户点击「· 免费版」或「· Pro版」后缀
- **THEN** 客户端 MUST 打开两档说明墙
- **AND** MUST NOT 打开三档 VIP/基础/间隔墙

### Requirement: Next-3-hours card SHALL stay visible with empty-window copy when bound

On the smart prediction page, when the user is logged in and baby-bound (not auth-guest chrome), the client MUST always show the「接下来3小时」card, including when there are no in-window forecast segments for the next three hours. When segments exist, the body MUST remain the existing joined timeline text (`HH:mm 左右{事件名}` connected by「 → 」). When segments are empty, the body MUST be exactly：`接下来 3 小时暂无事项，享受属于自己的时光吧。` The title row MUST NOT require an「AI分析」entry. Auth-guest chrome MUST continue to hide this card. 已绑定态下三小时卡 **必须** 常显；空窗正文 **必须** 为指定庆祝/空闲文案；**不得** 再要求「AI分析」入口；Auth 冷态仍隐藏。

#### Scenario: Empty window shows card with fixed copy

- **WHEN** the user is logged in and bound
- **AND** there are no forecast-enabled in-window events for the next three hours
- **THEN** the「接下来3小时」card MUST still be visible
- **AND** the body text MUST be「接下来 3 小时暂无事项，享受属于自己的时光吧。」
- **AND** the title row MUST NOT show「AI分析」

#### Scenario: Non-empty window unchanged body

- **WHEN** the user is logged in and bound
- **AND** there is at least one in-window timeline segment
- **THEN** the body MUST show the joined timeline segments as before
- **AND** MUST NOT show「AI分析」

#### Scenario: Auth guest still hides the card

- **WHEN** the user is not logged in or not baby-bound (auth-guest chrome)
- **THEN** the client MUST NOT show the「接下来3小时」card (including empty copy)

## ADDED Requirements

### Requirement: Smart prediction rows SHALL use affinity nextAt or affinity progress only

Visible smart-prediction rows, home feeding tip, and next-3-hours segments MUST consume affinity-rail `nextAt` values only. The client MUST NOT force recall-seed interval times onto those surfaces as a substitute prediction. When a row has no affinity `nextAt`, it MUST follow `predict-affinity-progress` for in-card progress chrome instead of showing a seed-based countdown presented as a forecast.

预测卡/tip/3h MUST 仅用亲和 nextAt；MUST NOT 用回忆种子间隔冒充预测；无 nextAt 时 MUST 走亲和进度。

#### Scenario: 未购 Pro 仍显示亲和预测

- **WHEN** 用户未开通 Pro 且某根亲和已产出 nextAt
- **THEN** 对应预测卡 MUST 显示该 nextAt/倒计时
- **AND** MUST NOT 仅因未开通而改回种子时刻
