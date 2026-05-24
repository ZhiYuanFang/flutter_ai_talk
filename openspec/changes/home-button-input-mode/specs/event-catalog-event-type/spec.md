## ADDED Requirements

### Requirement: 事件目录 eventType 与 extraNames 解析

The client SHALL parse `eventType` and `extraNames` from each `GET /device/history/api/event/options` `data.list[]` item in addition to existing `id`, `name`, `logo`, and `color`. 客户端必须从事件目录列表项解析 **`eventType`**（取值 **`number`**、**`time`**、**`one`**）与 **`extraNames`**（逗号分隔别名，可选）；`eventType` 缺失或未知时该事件不得用于按钮创建流程。

#### Scenario: 完整目录项

- **WHEN** 列表项包含 `id`、`name`、`eventType: "number"`、`extraNames: "喝奶,母乳"`、`color`、`logo`
- **THEN** 内存中的事件定义必须保留上述字段，且 `id` 字符串化后仍作为查找主键

#### Scenario: 未知 eventType

- **WHEN** 某列表项的 `eventType` 不在 `number|time|one` 集合内
- **THEN** 按钮模式网格不得对该项发起 `add`（可隐藏或置灰）

### Requirement: 目录缓存快照包含 eventType

The system SHALL include `eventType` and `extraNames` in local catalog JSON persistence and in remote-vs-local snapshot comparison for `event/options` refresh. 本地 `catalog` 缓存与远端对比逻辑必须将 **`eventType`**、**`extraNames`** 纳入 tracked 字段；变更时必须更新磁盘 JSON。

#### Scenario: 仅 eventType 变化

- **WHEN** 远端与本地 `id`、`name`、`logo`、`color` 相同但 `eventType` 不同
- **THEN** 系统必须持久化新目录并触发 UI 可读状态更新
