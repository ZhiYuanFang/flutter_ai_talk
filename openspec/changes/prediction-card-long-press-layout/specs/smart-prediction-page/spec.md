## ADDED Requirements

### Requirement: Portrait prediction cards SHALL long-press toggle list and grid layouts

On the smart prediction page in **portrait** orientation, when event cards are **not** demo-skeleton cards, a long-press on the whole event card MUST switch the persisted cards layout: from grid/waterfall to vertical list, or from vertical list to grid/waterfall. The switch MUST use the same local persistence as the title-bar layout toggle. The client MUST emit the same layout usage events as the title-bar toggle when the long-press switch succeeds. Demo-skeleton cards MUST NOT change layout on long-press. Landscape prediction cards MUST NOT use this long-press gesture to change the portrait layout preference. The title-bar layout toggle MUST remain available. Short-press card actions (add event, chart day summary, etc.) MUST remain governed by existing requirements.

智能预测**竖屏**且非骨架事件卡时，整卡长按 MUST 切换持久化布局：瀑布/网格 → 纵向列表，或纵向列表 → 瀑布/网格；MUST 与标题栏切换共用同一本地持久化；成功切换 MUST 上报与标题栏相同的布局 usage 事件。骨架 demo 卡长按 MUST NOT 改布局。横屏卡 MUST NOT 用该长按改竖屏布局偏好。标题栏布局切换 MUST 仍可用。短按既有行为 MUST 仍按既有需求。

#### Scenario: Long-press grid card opens list

- **WHEN** the portrait prediction page is in grid/waterfall layout with non-skeleton cards
- **AND** the user long-presses a whole event card
- **THEN** the cards layout becomes vertical list and is persisted

#### Scenario: Long-press list card opens grid

- **WHEN** the portrait prediction page is in vertical list layout with non-skeleton cards
- **AND** the user long-presses a whole event card
- **THEN** the cards layout becomes grid/waterfall and is persisted

#### Scenario: Skeleton ignores long-press layout

- **WHEN** the prediction page shows demo-skeleton cards
- **AND** the user long-presses a skeleton card
- **THEN** the cards layout MUST NOT change due to that long-press

#### Scenario: Title bar toggle remains

- **WHEN** the user uses the title-bar layout icon after long-press switching
- **THEN** the layout MUST still toggle and persist as before
