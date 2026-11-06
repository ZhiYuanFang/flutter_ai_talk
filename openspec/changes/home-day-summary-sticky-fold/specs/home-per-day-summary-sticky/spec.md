## MODIFIED Requirements

### Requirement: 吸顶高度 MUST 随 chip 折行可变

The day sticky header extent MUST equal the measured laid-out height of that day’s date label plus the currently visible summary chips (collapsed one-row or fully expanded), and MUST NOT leave a large empty band from overestimated row count. 日期吸顶的 `minExtent`/`maxExtent`（或等价）MUST 等于该日日期行 + **当前展示态** chip 区的**实测**高度；收起时为日期 + 一行 chip，展开时为日期 + 全部折行。MUST NOT 因偏大的折行估高在吸顶底部长期留出大块空白；MUST NOT 在有多行且已展开时用旧固定 ~30px 裁切。

#### Scenario: 收起态无底部空白

- **WHEN** 某日汇总 chip 实际仅需一行高度，吸顶处于默认收起态
- **THEN** 吸顶占用高度 MUST 贴近日期 + 一行 chip，MUST NOT 按多行估高留出明显空白

#### Scenario: 展开后完整可见

- **WHEN** 用户展开该日汇总且 chip 折多行
- **THEN** 吸顶 MUST 完整展示日期与全部 chip 行，高度 MUST 随实测更新

## ADDED Requirements

### Requirement: 按日汇总 chip MUST 默认一行并可展开收起

When a day’s summary chips would wrap beyond one row, the sticky header MUST default to showing a single clipped row and MUST offer expand/collapse; expand/collapse MUST NOT share the chip tap that opens the day chart. 当某日汇总 chip 折行将超过一行时，吸顶 MUST **默认**只展示**一行**（超出裁切），并 MUST 在日期行右侧提供「展开」/「收起」（或等价文案）；展开后 MUST 展示全部折行，再次收起 MUST 回到一行。仅一行即可容纳时 MUST NOT 强制展示展开控件。展开态 MUST **按日独立**（滚动到另一日 MUST NOT 要求继承展开）。点击汇总 chip 打开单日详图的行为 MUST 保持不变，MUST NOT 因点展开/收起而打开 Sheet。

#### Scenario: 多行默认收起

- **WHEN** 某日 chip 全高超过一行
- **THEN** 首屏该日吸顶 MUST 仅显示一行 chip，且 MUST 可见展开入口

#### Scenario: 展开与收起

- **WHEN** 用户点击该日日期行右侧「展开」
- **THEN** 该日 MUST 显示全部 chip 行，入口变为「收起」
- **AND WHEN** 用户再点「收起」
- **THEN** MUST 回到一行裁切

#### Scenario: chip 与展开手势分离

- **WHEN** 用户点击某一汇总 chip（非展开/收起控件）
- **THEN** 客户端 MUST 仍打开单日 `TrendDayDetailChart` Sheet，MUST NOT 仅切换展开态
