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

The center badge on the color boundary MUST display an emoji character (default `✨`, overridable by a shared constant) inside a white or semi-transparent circular capsule. The badge MUST use `IgnorePointer` so taps pass through to the underlying colored segments.

VS 条中心 MUST 使用 emoji 徽章（默认 `✨`），且 MUST 允许点击穿透至色带。

#### Scenario: 中心 emoji 展示

- **WHEN** VS 条渲染于任意表面（广场、详情、分享离屏）
- **THEN** 中心 MUST 展示 emoji 徽章而非纯文字 "VS"

#### Scenario: 点击 VS 徽章区域

- **WHEN** 用户点击中心 emoji 徽章所在区域且 `interactive=true`
- **THEN** 点击 MUST 由下方左/右色带之一接收并触发对应 side 投票

## MODIFIED Requirements

### Requirement: VS bar SHALL enforce minDisplayRatio and VS icon placement

When total votes > 0, each side's visual width MUST be at least `minDisplayRatio` (default `0.12`) of the bar before label placement. An emoji center badge MUST be centered on the color boundary between left and right macaron fills.

有票时每侧视觉宽度 MUST ≥ `minDisplayRatio`（默认 0.12）；emoji 徽章 MUST 位于色带分界中心。

#### Scenario: 极端比例钳制

- **WHEN** 左 1 票右 99 票
- **THEN** 左侧视觉宽度 MUST NOT 小于条宽的 12%
- **AND** emoji 徽章 SHALL 位于分界处
