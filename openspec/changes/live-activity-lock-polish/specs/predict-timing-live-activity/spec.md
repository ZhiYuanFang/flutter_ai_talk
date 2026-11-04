## MODIFIED Requirements

### Requirement: iOS client SHALL present Timing Live Activity separately and only from push

For in-progress timing on iOS, the client MUST provide a Live Activity configuration separate from Imminent. The lock-screen UI MUST use a two-tier layout: a narrow top row with the App name「胖宝」in the event accent color and MUST NOT show a circular App brand logo in that top row; a wider bottom row with the leading event logo resolved locally from `eventId` (fallback brand/orb if missing), the primary title equal to the event name without a「计时中」suffix (empty name MUST fall back to a short label such as「事件」, MUST NOT use「事件计时中」or「…计时中」), and a trailing system-driven elapsed timer from `startTime` (unix seconds) rendered with SwiftUI `Text(timerInterval:)` (or equivalent ActivityKit-live timer Text) with `countsDown: false`. The lock-screen elapsed timer MAY include seconds; the client MUST NOT require a seconds-free `hh:mm`-only format and MUST NOT apply a「under one minute displays as one minute」floor on that timer. The timer interval MUST use a finite upper bound from `startTime` (approximately 99 hours), MUST NOT rely on `Date.distantFuture` for the lock-screen Timing path, and MUST NOT be placed under the title as a secondary caption. Bottom-row event logo size MUST be approximately two-thirds of the prior two-tier lock-screen size (about 37pt when the prior size was 56pt). The UI MUST NOT show a trailing chevron/arrow. Event text color MUST follow the catalog color for that `eventId`, brightened when too dark against the Live Activity background tint. Timing ActivityAttributes (or equivalent fixed fields at start) MUST include `eventId` so the Extension can resolve visuals; the push MUST NOT be required to carry logo URL or color hex. The client MUST NOT locally `Activity.request` (or equivalent) a Timing Live Activity for this product path; presentation and dismissal MUST wait for server Push-to-Start / liveactivity start and end as specified by twin `predict-live-activity-push`. Multiple Timing Live Activities MUST be displayable concurrently when the system presents multiple activities.

iOS 进行中计时 MUST 使用与 Imminent 分离的 Live Activity 配置。锁屏 MUST 为双层：上层窄行仅 App 名「胖宝」（事件提亮色），MUST NOT 在上层展示圆形 App 品牌 logo；下层宽行按 `eventId` 本地解析的事件 logo（缺失则品牌/色球兜底）、主标题为事件名且 MUST NOT 追加「计时中」（空名 MUST 短兜底如「事件」，MUST NOT 使用「事件计时中」或「…计时中」），以及右侧自 `startTime`（unix 秒）起的系统驱动已计时（SwiftUI `Text(timerInterval:)` 或等价、`countsDown: false`）。锁屏已计时 MAY 含秒；MUST NOT 要求无秒的纯 `hh:mm`；MUST NOT 再对锁屏 timer 施加「不足 1 分钟按 1 分钟」。timer 区间 MUST 自 `startTime` 起有限上界（约 99 小时），锁屏 Timing 路径 MUST NOT 使用 `Date.distantFuture`；MUST NOT 作为标题下小字。下层事件 logo 尺寸 MUST 约为上一版双层锁屏的 2/3（上一版 56pt 时约 37pt）。MUST NOT 展示右箭头。文案色 MUST 跟随事件 catalog 色并在过深时提亮。Timing 起活动固定字段 MUST 含 `eventId`；推送 MUST NOT 被要求携带 logo/color。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Timing；展示与关闭 MUST 等待对端 `predict-live-activity-push` 的 start/end。系统同时下发多条时客户端 MUST 能并存展示。

#### Scenario: Separate Timing type

- **WHEN** 同时存在 Imminent 与 Timing Live Activity
- **THEN** 二者 MUST 为不同 Activity 配置，MUST NOT 用 Imminent 组件实例表达计时中

#### Scenario: Two-tier lock screen with live system timer

- **WHEN** 系统展示一条 Timing Live Activity 锁屏 content 且 `startTime` 为有效 unix 秒
- **THEN** UI MUST 含上层「胖宝」文案（无圆形 App logo）、下层事件图（或兜底）、无「计时中」后缀的事件名标题
- **AND** 下层右侧 MUST 以系统 `timerInterval`（或等价）展示自 `startTime` 起的已计时
- **AND** MUST NOT 展示「已过去…分钟」类中文已计时
- **AND** MUST NOT 仅在事件名下方以次要小字展示该时间
- **AND** MUST NOT 展示右箭头

#### Scenario: Title omits timing-in-progress suffix

- **WHEN** Timing 锁屏 ContentState/Attributes 事件名为「睡眠」
- **THEN** 主标题 MUST 为「睡眠」
- **AND** MUST NOT 为「睡眠计时中」

#### Scenario: Empty name short fallback

- **WHEN** Timing 锁屏事件名为空
- **THEN** 主标题 MUST 为短兜底（如「事件」）
- **AND** MUST NOT 为「事件计时中」或单独「计时中」作为锁屏主标题后缀形态

#### Scenario: Top row has no app brand mark

- **WHEN** 系统展示 Timing 锁屏双层 content
- **THEN** 上层 MUST 含「胖宝」
- **AND** MUST NOT 展示圆形 App brand logo

#### Scenario: Event logo about two-thirds prior size

- **WHEN** Timing 锁屏下层渲染事件 logo
- **THEN** logo 逻辑尺寸 MUST 约为先前双层锁屏 56pt 的 2/3（约 37pt）

#### Scenario: Local visual by eventId

- **WHEN** Timing 起活动 Attributes 含有效 `eventId` 且客户端已预置对应 App Group 视觉索引
- **THEN** 锁屏下层 MUST 使用该事件 logo 与（提亮后的）事件色
- **AND** 上层 App 名 MUST 使用同一提亮事件色
- **AND** MUST NOT 要求推送下发 logo 或 color

#### Scenario: No local request for Timing

- **WHEN** 用户在本机开始一条计时且 App 仍在前台
- **THEN** 客户端 MUST NOT 仅凭本地开始动作创建 Timing Live Activity

#### Scenario: Multiple Timing activities

- **WHEN** 系统同时呈现两条不同 history 对应的 Timing Live Activity
- **THEN** 客户端锁屏 MUST 允许同时展示二者

#### Scenario: No Chinese elapsed floor on lock screen

- **WHEN** Timing 锁屏已计时大于 0 且不足 60 秒
- **THEN** 右侧 MUST 由系统 timer 展示（MAY 含秒）
- **AND** MUST NOT 强制显示「已过去1分钟」或等价中文地板分钟文案
