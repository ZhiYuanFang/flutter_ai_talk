## ADDED Requirements

### Requirement: 历史主行展示格式

The system SHALL render each history row’s primary label as the string **`{事件名}:{动作}`**, using repository-provided `eventName` and `action` (or mapped equivalents). The system SHALL use an explicit placeholder when either part is missing (e.g. `未知事件:未命名动作`).

#### Scenario: 完整字段展示

- **WHEN** 一条历史记录包含事件名「喂奶」与动作「新增 120ml」
- **THEN** 列表主文案必须展示为 `喂奶:新增 120ml`（全角/半角冒号以实现为准，须全应用一致）

#### Scenario: 缺失字段占位

- **WHEN** 事件名为空而动作非空
- **THEN** 主文案仍必须可读且不得留空，须使用约定占位事件名

### Requirement: 点击进入详情二级页

The system SHALL navigate to a dedicated secondary screen when the user activates a history row, carrying enough identity to load that record.

#### Scenario: 从主页进入详情

- **WHEN** 用户在主页历史列表点击一条记录
- **THEN** 应用必须打开历史详情路由并展示该记录详情

### Requirement: 详情页手动编辑与保存

The system SHALL allow editing record fields on the detail screen (至少包含动作描述或与后端对齐的可编辑字段) and SHALL persist updates through the feed/history repository contract.

#### Scenario: 保存后列表同步

- **WHEN** 用户在详情页修改内容并成功保存
- **THEN** 返回主页后列表中对应行必须反映更新后的 `{事件名}:{动作}` 文本
