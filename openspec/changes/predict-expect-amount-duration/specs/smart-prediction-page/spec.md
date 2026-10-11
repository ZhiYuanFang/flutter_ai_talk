## ADDED Requirements

### Requirement: Prediction cards SHALL show winning expect as secondary copy

When a hot prediction card has a non-null `nextAt` prediction and a winning expect per `event-expect-prediction`, the client SHALL render a secondary line using unified「约」copy (e.g.「预计约1小时5分钟」or「预计约120毫升」). When there is no winning expect, the client MUST NOT reserve an empty placeholder for expect. Active-timing compact cards and cards without a pushable prediction MUST NOT be required to show expect. Landscape compact layout MAY omit the leaf title while keeping quantity/unit or duration.

热态卡在有胜出 expect 时 MUST 展示「预计约…」次级文案；无 expect MUST NOT 空白占位；计时中/无可推送预测不强制展示；横屏 MAY 省略叶子名。

#### Scenario: Show duration expect on card

- **WHEN** 热态卡存在 `nextAt` 且胜出 expect 为 duration
- **THEN** 卡片 MUST 展示含「预计约」与时长的次级文案

#### Scenario: Show amount expect on card

- **WHEN** 热态卡存在 `nextAt` 且胜出 expect 为 amount
- **THEN** 卡片 MUST 展示含「预计约」与数量（及单位若有）的次级文案

#### Scenario: No expect — no placeholder

- **WHEN** 热态卡有 `nextAt` 但无胜出 expect
- **THEN** 卡片 MUST NOT 展示空的预计用量/用时行
