## MODIFIED Requirements

### Requirement: Prediction cards SHALL show winning expect as secondary copy

When a hot prediction card has a non-null `nextAt` prediction and a winning expect per `event-expect-prediction`, the client SHALL render a secondary line using unified「约」copy (e.g.「预计约1小时5分钟」or「预计约120毫升»). When the card also renders a countdown block for that prediction, the expect line MUST be placed immediately above the countdown text (and MUST be below any hero logo that sits above that countdown). The client MUST NOT place the expect line in the title/meta section above the hero logo when a hero logo is shown above the countdown. When there is no winning expect, the client MUST NOT reserve an empty placeholder for expect. Active-timing compact cards and cards without a pushable prediction MUST NOT be required to show expect. Landscape compact layout MAY omit the leaf title while keeping quantity/unit or duration.

热态卡在有胜出 expect 时 MUST 展示「预计约…」次级文案；若同时展示倒计时区块，文案 MUST 紧贴倒计时上方（有大 logo 时 MUST 在 logo 与倒计时之间，MUST NOT 仍放在 logo 上方的标题区）；无 expect MUST NOT 空白占位；计时中/无可推送预测不强制展示；横屏 MAY 省略叶子名。

#### Scenario: Show duration expect on card

- **WHEN** 热态卡存在 `nextAt` 且胜出 expect 为 duration
- **THEN** 卡片 MUST 展示含「预计约」与时长的次级文案

#### Scenario: Show amount expect on card

- **WHEN** 热态卡存在 `nextAt` 且胜出 expect 为 amount
- **THEN** 卡片 MUST 展示含「预计约」与数量（及单位若有）的次级文案

#### Scenario: Expect sits above countdown under hero logo

- **WHEN** 竖屏热态卡展示倒计时上方大 logo，且存在胜出 expect
- **THEN** 「预计约…」MUST 出现在该 logo 下方、倒计时文案上方；MUST NOT 出现在该 logo 上方的标题/上次区

#### Scenario: Expect sits above countdown without hero logo

- **WHEN** 热态卡展示倒计时但不展示倒计时上方大 logo（如标题旁小 logo），且存在胜出 expect
- **THEN** 「预计约…」MUST 紧贴该倒计时文案上方

#### Scenario: No expect — no placeholder

- **WHEN** 热态卡有 `nextAt` 但无胜出 expect（含仅 one 历史的根）
- **THEN** 卡片 MUST NOT 展示空的预计用量/用时行
