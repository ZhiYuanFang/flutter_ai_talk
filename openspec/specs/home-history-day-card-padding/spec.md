## ADDED Requirements

### Requirement: 日历日记录卡片内边距

The client SHALL apply uniform inner padding between each calendar-day history card background and its timeline record rows. 每个按本地自然日分组的**记录卡片背景**（圆角色块）内部 MUST 在记录行与卡片边缘之间保留**统一内边距**（水平与竖直均须留白），不得让时间轴行紧贴卡片圆角内缘。

#### Scenario: 卡片内容与边缘留白

- **WHEN** 用户查看包含至少一条记录的某日历史卡片
- **THEN** 该卡片内所有记录行（含圆点列）MUST 整体相对卡片背景内缘缩进，且四向（或至少水平 + 上下）可见一致 padding

#### Scenario: 连线与行对齐

- **WHEN** 同一日卡片内存在两条及以上记录且绘制圆点连线
- **THEN** 内边距 MUST 同时作用于记录行与连线绘制层，MUST NOT 出现仅 pad 文字行而导致连线与圆点错位

#### Scenario: 不影响卡片间外边距

- **WHEN** 列表中存在相邻两个日历日卡片
- **THEN** 卡片之间的既有列表/外边距语义 MUST 保持不变；本需求仅增加**卡片内部** padding
