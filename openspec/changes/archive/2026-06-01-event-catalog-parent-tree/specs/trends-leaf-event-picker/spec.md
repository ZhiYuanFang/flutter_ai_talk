## ADDED Requirements

### Requirement: 趋势页仅可选叶子事件

The trends event picker SHALL list only leaf catalog entries with a valid `eventType`, and MUST NOT list parent events that have children. 趋势页事件选择器必须仅展示**叶子节点**，且必须具有合法 **`eventType`**；任何在 catalog 中存在子项的父级目录事件不得出现在列表中。

#### Scenario: 父级目录不可选

- **WHEN** 事件 P 在 catalog 中至少有一个子项
- **THEN** 趋势页 picker 不得展示 P

#### Scenario: 叶子可选

- **WHEN** 事件 L 无子项且 `eventType` 为 `number|time|one` 之一
- **THEN** L 必须出现在趋势页 picker 中

### Requirement: 趋势默认选中与失效 fallback

When the catalog loads or changes, the trends screen MUST keep `_selectedKey` pointing to a valid leaf or fall back to the first leaf in API order. 目录加载或变更时，趋势页当前选中项必须仍为有效叶子；若当前 key 为空、指向父节点或已不在 catalog 中，必须 fallback 到**第一个叶子**（API 顺序），并重新加载序列数据。

#### Scenario: 首次进入

- **WHEN** 用户打开趋势页且 catalog 含至少一个合法叶子
- **THEN** 默认选中项必须为第一个合法叶子，而非任意 `catalog.first`

#### Scenario: 选中项变为父节点

- **WHEN** 目录刷新后原选中 id 对应事件变为有子节点的父级
- **THEN** 必须自动切换到第一个合法叶子并刷新趋势序列
