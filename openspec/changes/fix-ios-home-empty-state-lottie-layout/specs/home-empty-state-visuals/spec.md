## ADDED Requirements

### Requirement: Cross-Platform Empty State Layout Parity
The home empty-state gallery SHALL render title, subtitle, and primary action (when provided) within the visible viewport on both iOS and Android, regardless of Lottie load outcome.
主页空状态画廊必须在 iOS 与 Android 上均将标题、副标题及主操作按钮（若提供）渲染于可视视口内，且不得因 Lottie 加载结果而裁切或隐藏上述文案与按钮。

#### Scenario: Unbound user on iOS sees invitation copy and bind button
- **WHEN** user is logged in, `deviceNo` is null or empty, history `items` is empty, and `initialLoadDone` is true on **iOS**
- **THEN** the body MUST display the title「嗨，我是胖宝！」（或等价未绑定邀请标题）
- **THEN** the body MUST display the subtitle encouraging binding
- **THEN** the body MUST display a tappable button labeled「立即绑定宝宝」（或基线等价文案）
- **THEN** tapping the button MUST navigate to the baby binding flow

#### Scenario: Bound user with no records on iOS sees encouragement copy
- **WHEN** user is logged in, `deviceNo` is valid, history `items` is empty, and `initialLoadDone` is true on **iOS**
- **THEN** the body MUST display encouragement text including the baby nickname (e.g.「还没有为 [昵称] 记录哦」)
- **THEN** the subtitle MUST remain visible below the animation slot

#### Scenario: Animation slot bounded size on iOS
- **WHEN** the empty-state gallery is visible on **iOS**
- **THEN** the Lottie or fallback illustration slot MUST NOT expand to consume the entire history `Expanded` region such that text siblings are clipped or off-screen

### Requirement: Empty State Animation Fallback
When the Lottie asset fails to load or renders as an invalid/empty composition, the system SHALL still show the empty-state copy and actions, and SHALL display a static fallback in the animation slot.
当 Lottie 资源加载失败或渲染为无效/空 composition 时，系统仍必须展示空状态文案与操作，并在动画槽位展示静态兜底内容。

#### Scenario: Invalid Lottie JSON on iOS
- **WHEN** the configured Lottie JSON is missing required animation data (e.g. stub `{}`) on **iOS**
- **THEN** title, subtitle, and bind button (unbound case) MUST remain visible and interactive
- **THEN** the animation slot MUST show a static fallback (icon or bundled image) within bounded dimensions, not an unbounded gray block covering the content area
