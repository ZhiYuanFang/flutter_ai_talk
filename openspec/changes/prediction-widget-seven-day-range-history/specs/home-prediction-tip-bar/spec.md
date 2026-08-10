## ADDED Requirements

### Requirement: Home prediction tip SHALL use seven-day range history store

The feeding-home fixed prediction tip（最近下一步）SHALL compute `predictAllUpcoming` / nearest tip from the isolated seven-day range history store shared with the smart prediction page and desktop widget, not from feeding-home pagination depth alone. When the range store is loading and no prior range cache exists, the tip MAY show a neutral empty/loading affordance；it MUST recompute when the range store updates after fetch or invalidation.

喂养顶栏预测贴士 **必须** 基于与预测页/小组件共享的 7 日 range store 计算，**不得** 仅依赖喂养分页已加载深度作为预测历史唯一来源。

#### Scenario: 与预测页同源历史

- **WHEN** range store 已加载完成
- **THEN** 顶栏选用的「最近下一步」MUST 基于该 store 的 history（再叠加推演开关与 skip）

#### Scenario: range 更新后重算

- **WHEN** range store 因拉取完成或历史变更失效重拉而更新
- **THEN** 顶栏 MUST 重新计算展示的预测贴士
