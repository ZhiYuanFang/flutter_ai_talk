## ADDED Requirements

### Requirement: parentId 解析与根节点判定

The client SHALL parse optional `parentId` from each `GET /device/history/api/event/options` list item and treat missing, null, or blank values as a root-level catalog entry. 客户端必须从目录项解析可选字段 **`parentId`**；字段缺失、`null` 或空串（含仅空白）必须视为**一级目录**（根节点）；非空值 trim 后字符串化，与事件 **`id`** 采用相同比较规则。

#### Scenario: 一级目录项

- **WHEN** 列表项含 `id`、`name` 且无 `parentId` 或 `parentId` 为空串
- **THEN** 内存中该事件的 `parentId` 必须为 `null`，且必须被识别为根节点

#### Scenario: 子目录项

- **WHEN** 列表项 `parentId` 指向另一有效事件的 `id`
- **THEN** 该事件不得被识别为根节点，且必须出现在 `childrenOf(parentId)` 结果中

### Requirement: parentId 本地持久化与快照对比

The system SHALL persist `parentId` in local catalog JSON and include it in remote-vs-local snapshot comparison. 本地 catalog 缓存的 JSON 与远端刷新对比逻辑必须包含 **`parentId`**；仅 `parentId` 变化时也必须更新磁盘并通知 UI。

#### Scenario: 仅 parentId 变化

- **WHEN** 远端与本地某 `id` 的 `name`、`eventType` 等相同但 `parentId` 不同
- **THEN** 系统必须持久化新目录并触发可读状态更新

### Requirement: 事件目录树索引

The system SHALL provide pure functions to query root events, children of a parent id, whether an event has children, and leaf events while preserving API list order. 系统必须提供纯函数：在保持 **API 返回顺序** 的前提下查询根节点列表、指定父 id 的子节点、某 id 是否有子节点、以及叶子节点集合。

#### Scenario: 叶子节点定义

- **WHEN** catalog 中不存在任何项的 `parentId` 等于事件 E 的 `id`
- **THEN** E 必须被判定为叶子节点

#### Scenario: 有子节点判定

- **WHEN** catalog 中存在至少一项的 `parentId` 等于事件 F 的 `id`
- **THEN** F 必须被判定为「有子节点」
