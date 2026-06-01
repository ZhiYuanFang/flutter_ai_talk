# trends-leaf-event-picker 规格增量

## MODIFIED Requirements

### Requirement: 趋势默认选中与失效 fallback
When the catalog loads or changes, the trends screen MUST keep `_selectedKey` pointing to a valid leaf, prefer restoring last remembered valid selection, or fall back to the first leaf in API order.

目录加载或变更时，趋势页当前选中项必须仍为有效叶子；进入页面时若存在“上次记忆且仍有效”的事件，必须优先恢复该事件；若当前 key 为空、指向父节点、已不在 catalog 中，或记忆无效，必须 fallback 到**第一个叶子**（API 顺序），并重新加载序列数据。

#### Scenario: 首次进入且存在有效记忆

- **WHEN** 用户打开趋势页，catalog 含至少一个合法叶子，且本地记忆事件仍有效
- **THEN** 默认选中项必须为该记忆事件，而非固定第一个叶子

#### Scenario: 首次进入且无有效记忆

- **WHEN** 用户打开趋势页且 catalog 含至少一个合法叶子，但本地记忆缺失或无效
- **THEN** 默认选中项必须为第一个合法叶子，而非任意 `catalog.first`

#### Scenario: 选中项变为父节点

- **WHEN** 目录刷新后原选中 id 对应事件变为有子节点的父级
- **THEN** 必须自动切换到第一个合法叶子并刷新趋势序列
