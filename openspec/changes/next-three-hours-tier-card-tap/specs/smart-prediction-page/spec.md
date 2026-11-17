## MODIFIED Requirements

### Requirement: Next-3-hours card SHALL show AI分析 entry and full body text

When the next-3-hours timeline block is shown on the smart prediction page, the client MUST show the timeline body in full without expand/collapse controls. The title row MUST NOT render an「AI分析」control and MUST NOT navigate to a retired AI analysis page. The card body, empty areas, and the fixed title text「接下来3小时」MUST NOT navigate to the feeding pager. When Free/Pro tier chrome is **ready**（非 syncing）, tapping **anywhere on the card**（including title「接下来3小时」、tier suffix、optional `Icons.upgrade`、body）MUST open the two-tier Free/Pro wall per `predict-free-pro-chrome`, including when the current suffix is Pro版. When chrome is syncing, the card MUST NOT open the wall. When the ready suffix is 免费版, the title row MUST show `Icons.upgrade` beside the free label per `predict-free-pro-chrome`. This supersedes prior「ONLY that suffix MAY be tappable」rules from `align-go-free-predict-retire` / older tier-wall deltas.

当展示「接下来3小时」块时，正文 **必须** 全量展示且无展开/收起；**不得** 显示「AI分析」或进入已删 AI 分析页；整卡/正文/「接下来3小时」六字 **不得** 进喂养；档位就绪时 **整卡**（含 Pro）MUST 开两档墙；免费版 MUST 旁挂 `Icons.upgrade`；syncing MUST NOT 开墙。

#### Scenario: 有三小时则无 AI分析

- **WHEN** 智能预测页正在展示「接下来3小时」时间线块
- **THEN** 标题行 MUST NOT 显示「AI分析」按钮
- **AND** MUST NOT 显示「展开」或「收起」

#### Scenario: 整卡与正文不进喂养

- **WHEN** 用户点击三小时卡正文或标题区
- **THEN** 客户端 MUST NOT 因此切换到喂养主页

#### Scenario: 非 syncing 整卡开墙

- **WHEN** Free/Pro 档位 chrome 已就绪且用户点击三小时卡任意区域（含正文）
- **THEN** 客户端 MUST 打开免费/Pro 两档墙
- **AND** 初始档 MUST 对应当前标题后缀

#### Scenario: Pro 整卡同样开墙

- **WHEN** 当前后缀为「· Pro版」且用户点击三小时卡正文
- **THEN** 客户端 MUST 打开两档墙且初始为 Pro版
