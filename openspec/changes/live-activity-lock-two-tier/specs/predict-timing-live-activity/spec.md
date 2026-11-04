## MODIFIED Requirements

### Requirement: iOS client SHALL present Timing Live Activity separately and only from push

For in-progress timing on iOS, the client MUST provide a Live Activity configuration separate from Imminent. The lock-screen UI MUST use a two-tier layout: a narrow top row with the circular App brand logo and the App name「胖宝」in the event accent color; a wider bottom row with the leading event logo resolved locally from `eventId` (fallback brand/orb if missing), the primary title indicating timing in progress with existing「…计时中」semantics unchanged (`timingLockTitle`), and a trailing Chinese minute-granularity elapsed copy from `startTime` (unix seconds) on the right—not a small caption under the title and not a second-precision digital timer. Elapsed copy MUST be「已过去h时m分钟」when hours ≥ 1, and「已过去m分钟」when hours are 0 (MUST NOT write「0时」). Any positive elapsed under one minute MUST be treated as `m = 1`. Bottom-row event logo and title/time typography MUST be approximately twice the previous single-row lock-screen scale. The UI MUST NOT show a trailing chevron/arrow. Event text color MUST follow the catalog color for that `eventId`, brightened when too dark against the Live Activity background tint. Timing ActivityAttributes (or equivalent fixed fields at start) MUST include `eventId` so the Extension can resolve visuals; the push MUST NOT be required to carry logo URL or color hex. The client MUST NOT locally `Activity.request` (or equivalent) a Timing Live Activity for this product path; presentation and dismissal MUST wait for server Push-to-Start / liveactivity start and end as specified by twin `predict-live-activity-push`. Multiple Timing Live Activities MUST be displayable concurrently when the system presents multiple activities.

iOS 进行中计时 MUST 使用与 Imminent 分离的 Live Activity 配置。锁屏 MUST 为双层：上层窄行圆形 App 品牌 logo + App 名「胖宝」（事件提亮色）；下层宽行按 `eventId` 本地解析的事件 logo（缺失则品牌/色球兜底）、计时中语义主标题（既有「…计时中」/`timingLockTitle` 不变），以及右侧自 `startTime`（unix 秒）起的中文到分钟已计时（靠右，MUST NOT 作为标题下小字，MUST NOT 用秒级数字计时）。满 1 小时 MUST 为「已过去h时m分钟」；不足 1 小时 MUST 为「已过去m分钟」（MUST NOT 写「0时」）。已计时大于 0 且不足 1 分钟 MUST 按 `m = 1`。下层事件 logo 与标题/时间字号 MUST 相对原单行锁屏约放大一倍。MUST NOT 展示右箭头。文案色 MUST 跟随事件 catalog 色并在过深时提亮。Timing 起活动固定字段 MUST 含 `eventId`；推送 MUST NOT 被要求携带 logo/color。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Timing；展示与关闭 MUST 等待对端 `predict-live-activity-push` 的 start/end。系统同时下发多条时客户端 MUST 能并存展示。

#### Scenario: Separate Timing type

- **WHEN** 同时存在 Imminent 与 Timing Live Activity
- **THEN** 二者 MUST 为不同 Activity 配置，MUST NOT 用 Imminent 组件实例表达计时中

#### Scenario: Two-tier lock screen with Chinese elapsed

- **WHEN** 系统展示一条 Timing Live Activity 锁屏 content 且 `startTime` 为有效 unix 秒
- **THEN** UI MUST 含上层圆形 App logo 与「胖宝」、下层事件图（或兜底）、「…计时中」标题
- **AND** 下层右侧 MUST 以中文到分钟展示已计时
- **AND** MUST NOT 仅在事件名下方以次要小字展示该时间
- **AND** MUST NOT 展示右箭头

#### Scenario: Sub-hour elapsed omits zero hours

- **WHEN** Timing 已计时约 5 分钟（不足 1 小时）
- **THEN** 锁屏右侧 MUST 显示「已过去5分钟」
- **AND** MUST NOT 显示「已过去0时5分钟」

#### Scenario: Elapsed includes hours when at least one hour

- **WHEN** Timing 已计时约 1 小时 23 分钟
- **THEN** 锁屏右侧 MUST 显示「已过去1时23分钟」

#### Scenario: Sub-minute elapsed rounds to one minute

- **WHEN** Timing 已计时大于 0 且不足 60 秒
- **THEN** 锁屏右侧 MUST 显示「已过去1分钟」
- **AND** MUST NOT 显示「已过去0分钟」

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

## ADDED Requirements

### Requirement: Timing Dynamic Island time SHALL always use hh:mm:ss

When the system presents a Timing Live Activity on Dynamic Island (compact trailing and expanded trailing time slot), the elapsed time MUST be formatted as zero-padded `hh:mm:ss` at all times, including when elapsed time is under one hour. The island MUST NOT collapse to `mm:ss`-only presentation for sub-hour elapsed. Compact trailing MUST remain inside the existing short intrinsic-width slot (`"00:00:00"` placeholder behavior) and MUST NOT use lock-screen Chinese minute copy.

当系统以 Dynamic Island（compact trailing 与 expanded trailing 时间位）展示 Timing Live Activity 时，已计时 MUST 始终格式化为零填充的 `hh:mm:ss`，含不足 1 小时的情形。MUST NOT 在不足 1 小时时收成仅 `mm:ss`。compact trailing MUST 仍落在既有短固有宽占位槽（`"00:00:00"`）内，MUST NOT 使用锁屏中文到分钟文案。

#### Scenario: Sub-hour island elapsed keeps hours field

- **WHEN** Timing compact/expanded 已计时约 5 分 23 秒
- **THEN** 时间位 MUST 显示等价于 `00:05:23` 的 `hh:mm:ss`
- **AND** MUST NOT 仅显示 `05:23`
