## ADDED Requirements

### Requirement: Smart prediction page SHALL show at most one care-alert banner between tip and list

The smart prediction page SHALL render a care-alert banner slot between the tip card region and the prediction event list. When the care-alert engine returns a non-null Top1 alert, the slot MUST show exactly one banner whose primary tone/label uses「值得留意」. When the engine returns null, the page MUST hide the entire banner block (no empty placeholder). The banner MUST remain evaluable even when the tip card is absent.

智能预测页 **必须** 在 tip 区与推演列表之间提供预警槽；有 Top1 时 **必须** 展示恰好一条「值得留意」Banner；无预警时 **必须** 整块隐藏；tip 缺失时 Banner **仍可** 单独出现。

#### Scenario: 有预警展示一条

- **WHEN** 护理留意引擎产出一条间隔拉长 Top1
- **THEN** tip 与事件列表之间 MUST 展示恰好一条「值得留意」Banner
- **AND** MUST NOT 同时展示第二条预警 Banner

#### Scenario: 无预警隐藏

- **WHEN** 护理留意引擎结果为 null
- **THEN** 页面 MUST NOT 渲染预警 Banner 占位块

### Requirement: Tapping care-alert banner SHALL open structured reason page

Tapping the care-alert banner SHALL navigate to a dedicated care-alert detail route that presents the structured reason for that Top1 alert. The page MUST explain why the alert fired using the engine’s reason fields (not only the banner one-liner).

点 Banner **必须** 进入专用详情路由，并 **必须** 用结构化原因说明为何触发，而非仅重复 Banner 一行摘要。

#### Scenario: 点进详情

- **WHEN** 用户点击「值得留意」Banner
- **THEN** 客户端 MUST 导航至护理留意详情页
- **AND** 详情 MUST 展示该 Top1 的结构化原因字段
