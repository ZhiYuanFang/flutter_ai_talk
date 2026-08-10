## ADDED Requirements

### Requirement: Compact prediction layout SHALL be a two-column waterfall

When the smart prediction page uses the compact (non-list) card layout, event cards SHALL be arranged in a two-column waterfall (masonry-like) such that card heights follow content and MUST NOT be forced to a uniform cell aspect ratio. The compact layout MUST remain the default for first-time users, and the user’s list-vs-compact choice MUST continue to persist locally. The persisted compact preference MAY reuse the existing `grid` storage value.

智能预测紧凑布局 **必须** 为双列瀑布流（高度随内容，**不得** 强制统一宽高比）；紧凑 **必须** 仍为首次默认；列表/紧凑偏好 **必须** 本地持久化（紧凑键可沿用既有 `grid`）。

#### Scenario: 瀑布流非等高

- **WHEN** 布局为紧凑且存在至少两张内容高度不同的事件卡
- **THEN** 双列排列 MUST 允许卡片顶边不对齐（错落）
- **AND** MUST NOT 使用强制统一 `childAspectRatio` 裁切内容

#### Scenario: 默认与记忆

- **WHEN** 用户首次无布局偏好打开智能预测页
- **THEN** MUST 以紧凑（瀑布流）展示
- **AND** 用户切到列表并重启后 MUST 仍为列表

### Requirement: Waterfall cards SHALL place a larger event logo above the countdown

In compact/waterfall cards, when forecast is enabled and a prediction exists, the client MUST show a larger centered event logo above the countdown (and MUST NOT require a small logo in the title row). The title row MUST still show the event name and forecast toggle. Countdown and overdue copy rules from prior changes MUST remain unchanged.

瀑布流卡在推演开启且可预测时，**必须** 在倒计时上方居中展示更大事件图，标题行 **不得** 再要求小 logo；标题行 **必须** 仍有事件名与推演开关；倒计时/超时规则不变。

#### Scenario: 图在倒计时上

- **WHEN** 紧凑布局下事件 A 推演开启且可预测
- **THEN** 卡片 MUST 在倒计时上方展示居中放大的事件 logo
- **AND** 标题行 MUST NOT 再放置该事件小 logo（仅名 + 开关）

### Requirement: Soonest upcoming event logo SHALL pulse with a heartbeat animation

Among compact cards that are forecast-enabled, have a prediction, and are not overdue, the client MUST pick the event with the earliest `nextAt` and MUST apply a continuous heartbeat (scale pulse) animation to that card’s large logo. Other cards’ logos MUST remain static. If no such non-overdue predicted event exists, no heartbeat animation is required.

在推演开启、可预测且未超时的事件中，**必须** 对 `nextAt` 最早者的大图施加持续心跳缩放；其它卡大图静止；若无此类事件则不要求心跳。

#### Scenario: 最近未超时者心跳

- **WHEN** 紧凑布局下事件 A 的 `nextAt` 早于其它未超时可预测事件，且 A 推演开启
- **THEN** A 的大图 MUST 持续心跳动画
- **AND** 其它事件大图 MUST NOT 同步心跳

#### Scenario: 全超时无心跳

- **WHEN** 所有可预测开启事件均已逾期
- **THEN** 紧凑卡大图 MUST NOT 被要求展示心跳动画
