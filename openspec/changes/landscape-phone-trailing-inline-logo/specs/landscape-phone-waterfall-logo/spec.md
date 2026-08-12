## ADDED Requirements

### Requirement: 手机横屏第二行及以后卡片 MUST 将事件 logo 置于名称左侧

On phone landscape prediction waterfall (`Orientation.landscape` and `MediaQuery.size.shortestSide < 600`), for non-active-timing compact cards whose **index within their waterfall column is greater than 0** (i.e. not on the visual first row), the event logo MUST appear to the left of the event name, and the client MUST NOT render the large centered hero logo above the countdown on those cards. 在手机横屏预测瀑布流（横屏且 `shortestSide < 600`）中，非计时中的 compact 卡片若在其列内的行索引大于 0（不在视觉第一行），事件 logo MUST 出现在标题行事件名称左侧，且 MUST NOT 再渲染倒计时上方的居中大 logo。

#### Scenario: 手机横屏第二行普通卡

- **WHEN** 手机横屏瀑布流渲染某列中行索引 ≥ 1 的普通（非计时中）预测卡
- **THEN** 标题行 MUST 在事件名称左侧展示小尺寸事件 logo
- **AND** MUST NOT 在倒计时上方展示居中大 logo

#### Scenario: 手机横屏第一行维持大 logo

- **WHEN** 手机横屏瀑布流渲染每列行索引为 0 的普通卡（共同构成视觉第一行）
- **THEN** MUST 保持倒计时上方居中大 logo
- **AND** 标题行 MUST NOT 再额外塞一枚侧 logo
- **AND** MUST NOT 仅因列索引 > 0 而改为侧 logo

### Requirement: 平板横屏 MUST NOT 应用后续行侧 logo 规则

On tablet landscape (`shortestSide >= 600`), prediction waterfall cards MUST keep the pre-change compact logo layout for all rows/columns; the phone later-row inline-logo rule MUST NOT apply. 在平板横屏（`shortestSide >= 600`）下，预测瀑布流 MUST 保持变更前的 compact logo 布局；MUST NOT 套用手机后续行侧 logo 规则。

#### Scenario: 平板横屏各卡不变

- **WHEN** 平板横屏展示多列预测卡
- **THEN** 各卡普通态 MUST 仍使用倒计时上方大 logo（与变更前一致）

### Requirement: 后续行可见 logo MUST 承接飞入锚点与 soonest 心跳

When a card uses the title-inline logo layout, the fly-to landing `logoAnchorKey` MUST wrap that inline logo, and if the card is the soonest heartbeat target, the heartbeat wrapper MUST apply to that visible logo. 当卡片使用标题旁 logo 布局时，飞入落点 `logoAnchorKey` MUST 包裹该侧 logo；若为 soonest 心跳目标，心跳 MUST 作用在该可见 logo 上。

#### Scenario: 第二行 soonest 心跳

- **WHEN** soonest 心跳事件落在手机横屏非首行且为普通卡
- **THEN** 心跳动效 MUST 出现在标题旁小 logo 上
