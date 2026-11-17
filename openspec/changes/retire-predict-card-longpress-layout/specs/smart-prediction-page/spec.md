## ADDED Requirements

### Requirement: Portrait prediction cards MUST NOT long-press toggle list and grid layouts

On the smart prediction page in **portrait** orientation, a long-press on an event card (including non-skeleton hot cards) MUST NOT switch the persisted cards layout between grid/waterfall and vertical list. Layout changes MUST occur only via the title-bar layout toggle (or other explicitly documented non-long-press controls). Short-press card actions (add event, chart day summary, etc.) MUST remain governed by existing requirements. Landscape cards MUST continue to not use card long-press to change the portrait layout preference.

竖屏预测事件卡长按 MUST NOT 切换 list/瀑布布局；布局切换 MUST 仅经标题栏（或其它非长按的明示控件）。短按既有行为不变。

#### Scenario: Long-press does not leave grid

- **WHEN** 竖屏为瀑布/网格布局且展示热态卡
- **AND** 用户长按整张事件卡
- **THEN** 卡片布局 MUST NOT 因该长按变为纵向列表

#### Scenario: Long-press does not leave list

- **WHEN** 竖屏为纵向列表布局且展示热态卡
- **AND** 用户长按整张事件卡
- **THEN** 卡片布局 MUST NOT 因该长按变为瀑布/网格

#### Scenario: Title bar toggle remains

- **WHEN** 用户点击标题栏布局图标
- **THEN** 布局 MUST 仍按既有标题栏规则切换并持久化

## REMOVED Requirements

### Requirement: Portrait prediction cards SHALL long-press toggle list and grid layouts

**Reason**: 产品去除卡长按进准确率/切布局，避免误触；改由标题栏独占切换。

**Migration**: 删除整卡 `onLongPress` 布局切换接线；保留标题栏 toggle 与 `predictionCardsLayout` 持久化。
