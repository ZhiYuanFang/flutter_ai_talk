## ADDED Requirements

### Requirement: UcgDebateVsBar SHALL be the single VS visualization across surfaces

The Flutter app MUST implement `UcgDebateVsBar` as the only widget rendering debate stance bars on square feed cards, profile timeline cards, post detail header, and offscreen share capture. All surfaces MUST pass consistent `leftLabel`, `rightLabel`, vote ratios, `myVoteSide`, and `interactive` flags.

Flutter MUST 以 `UcgDebateVsBar` 作为广场、个人时间线、详情、分享截图的唯一 VS 条组件。

#### Scenario: 广场与详情使用同一组件

- **WHEN** 用户浏览广场卡片与打开同帖详情
- **THEN** 两处 VS 条 MUST 由 `UcgDebateVsBar` 渲染且视觉参数一致

### Requirement: VS bar SHALL display percentages only never raw counts

The widget MUST render left and right percentages (rounded integer `%` text) when total votes > 0. It MUST NOT display `leftVoteCount`, `rightVoteCount`, or any absolute vote number in the UI.

UI MUST 仅展示百分比整数，MUST NOT 展示原始票数。

#### Scenario: 有票时展示百分比

- **WHEN** 左 3 票右 7 票
- **THEN** UI SHALL 展示约 `30%` 与 `70%`
- **AND** MUST NOT 展示 `3` 或 `7`

#### Scenario: 零票对称无数字

- **WHEN** `leftVoteCount + rightVoteCount == 0`
- **THEN** 条带 SHALL 50/50 对称
- **AND** MUST NOT 渲染任何百分比数字

### Requirement: VS bar SHALL enforce minDisplayRatio and VS icon placement

When total votes > 0, each side's visual width MUST be at least `minDisplayRatio` (default `0.12`) of the bar before label placement. A VS icon MUST be centered on the color boundary between left and right fills.

有票时每侧视觉宽度 MUST ≥ `minDisplayRatio`（默认 0.12）；VS 图标 MUST 位于色带分界中心。

#### Scenario: 极端比例钳制

- **WHEN** 左 1 票右 99 票
- **THEN** 左侧视觉宽度 MUST NOT 小于条宽的 12%
- **AND** VS 图标 SHALL 位于分界处

### Requirement: VS bar interactive mode SHALL gate tap-to-vote

When `interactive=true`, tapping the left or right colored segment MUST invoke vote for that side; the tap target width MUST match the segment's visual width (including `minDisplayRatio` clamping), not a fixed 50/50 split. When `interactive=false`, the bar MUST NOT respond to taps. Square feed and detail SHALL use `interactive=true`; profile timeline list SHALL use `interactive=false`.

`interactive=true` 时点击对应色带须触发投票，热区宽度 MUST 与色带视觉宽度一致；个人时间线列表 MUST 使用 `interactive=false`。

#### Scenario: 广场可点击投票

- **WHEN** 已登录用户在广场卡片点击 VS 条右侧
- **THEN** App SHALL 调用 vote API `side: right`

#### Scenario: 个人列表不可投票

- **WHEN** 用户在个人时间线浏览自己的辩论帖
- **THEN** VS 条 SHALL `interactive=false` 且 MUST NOT 触发 vote
