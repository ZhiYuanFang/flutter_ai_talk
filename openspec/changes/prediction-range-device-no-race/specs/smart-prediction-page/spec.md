## ADDED Requirements

### Requirement: Smart prediction empty state SHALL distinguish loading from true empty range

The smart prediction page MUST NOT show the final copy「暂无可用预测数据」(or equivalent) while the seven-day range store is still loading or not ready. That empty copy MUST be shown only when the range store is ready and the derived event row list is empty. While loading or not ready, the page MUST show a loading affordance instead.

智能预测页在 range **加载中或未 ready** 时 **不得** 展示「暂无可用预测数据」；该文案 **必须** 仅在 range 已 ready 且事件行为空时出现；加载中 **必须** 展示加载中提示。

#### Scenario: 未就绪显示加载

- **WHEN** 用户打开智能预测页且 range store 正在加载或尚未 ready
- **THEN** 事件卡片区 MUST 显示加载中（或等价）
- **AND** MUST NOT 显示「暂无可用预测数据」

#### Scenario: ready 且无事件才真空

- **WHEN** range store 已 ready 且由该 store 派生的预测事件行为空
- **THEN** 事件卡片区 MUST 显示「暂无可用预测数据」（或等价真空文案）
