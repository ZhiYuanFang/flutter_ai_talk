## ADDED Requirements

### Requirement: VS bar SHALL use macaron soft-candy visual style without blur

`UcgDebateVsBar` MUST render left and right stance segments with macaron pastel gradients (default雾蓝 `#A8D4F0` family and coral `#FFB5C5` family), large corner radius (~20 logical px), and increased bar height (~52–56 logical px) for a soft-candy appearance suited to the target audience. The widget MUST NOT use `BackdropFilter` on any VS bar surface (feed, detail, profile, share).

VS 条 MUST 采用马卡龙软糖渐变色带与大圆角，且 MUST NOT 使用 blur。

#### Scenario: 广场 VS 条可爱态

- **WHEN** 用户在推荐 Feed 浏览辩论卡 VS 条
- **THEN** 色带 MUST 呈现马卡龙渐变软糖形态
- **AND** MUST NOT 使用 `BackdropFilter`

#### Scenario: 选中侧视觉反馈

- **WHEN** 用户已投票且 `myVoteSide` 为 `left` 或 `right`
- **THEN** 对应色带 MUST 展示加强白边或轻阴影以标示选中
- **AND** MUST NOT 展示原始票数

### Requirement: VS bar center badge SHALL use emoji instead of VS text

The center badge on the color boundary MUST display an emoji character (default `✨`, overridable by a shared constant) inside a white or semi-transparent circular capsule. The badge MUST use `IgnorePointer` so taps pass through to the underlying colored segments. Each colored segment MUST have its own tap target aligned with visual width (50/50 hot zones when interactive).

VS 条中心 MUST 使用 emoji 徽章；左右色带 MUST 各自接收点击。

#### Scenario: 中心 emoji 展示

- **WHEN** VS 条渲染于任意表面（广场、详情、分享离屏）
- **THEN** 中心 MUST 展示 emoji 徽章而非纯文字 "VS"

#### Scenario: 点击左半区投票

- **WHEN** 用户点击 VS 条左半可视区域且 `interactive=true`
- **THEN** App SHALL 触发 `side: left` 投票

## MODIFIED Requirements

### Requirement: VS bar SHALL enforce minDisplayRatio and VS icon placement

When total votes > 0, each side's visual width MUST be at least `max(minDisplayRatio × barWidth, labelIntrinsicWidth + padding)` so stance labels (≤5 chars) MUST render fully without ellipsis. An emoji center badge MUST be centered on the color boundary between left and right macaron fills. When total votes is 0, the bar MUST be symmetric and MUST NOT show percentage numbers.

有票时每侧宽度 MUST ≥ max(12% 条宽, 文案完整宽)；立场标签 MUST 完整展示且 MUST NOT ellipsis；0 票 MUST 对称且无百分比数字。

#### Scenario: 极端比例钳制

- **WHEN** 左 1 票右 99 票
- **THEN** 左侧视觉宽度 MUST NOT 小于条宽的 12%
- **AND** emoji 徽章 SHALL 位于分界处

#### Scenario: 零票对称

- **WHEN** 总票数为 0
- **THEN** VS 条 MUST 左右对称
- **AND** MUST NOT 显示百分比数字

#### Scenario: 极端票差仍完整展示立场文案

- **WHEN** 一侧票数为 1、另一侧为 99 且立场标签为 5 字
- **THEN** 两侧色带 MUST 完整展示立场文字（MUST NOT 使用 ellipsis）
- **AND** 窄侧宽度 MUST 至少容纳该侧文案（可 scaleDown 缩小字号）

#### Scenario: 中心 emoji 不遮挡立场文案

- **WHEN** VS 条渲染且两侧均有立场标签
- **THEN** 每侧布局 MUST 为中心徽章半宽（18 logical px）保留内缘安全区
- **AND** 立场文字 MUST NOT 被 emoji 徽章遮挡
