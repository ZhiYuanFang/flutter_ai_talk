## MODIFIED Requirements

### Requirement: iOS client SHALL present Imminent as a dedicated Live Activity type

On iOS, the client MUST provide an ActivityKit Live Activity configuration dedicated to predict-imminent (separate ActivityAttributes from Timing). When the system delivers a Push-to-Start / liveactivity start for Imminent, the lock-screen UI MUST use a two-tier layout: a narrow top row with the App name「胖宝」in the event accent color and MUST NOT show a circular App brand logo in that top row; a wider bottom row with the leading event logo resolved locally from `eventId` (fallback brand/orb if missing), the primary title copy (existing `lockTitle` semantics unchanged), and—when not overdue—a trailing Chinese minute-granularity countdown. While `now` is before `nextAt`, the trailing copy MUST be「预计m分钟后」where `m` is the remaining time in whole minutes (total minutes, not split into hours), and any positive remainder under one minute MUST be treated as `m = 1`. When current time is at or after `nextAt`, the trailing slot MUST NOT show「已过时」or any other time-dimension copy. Bottom-row event logo size MUST be approximately two-thirds of the prior two-tier lock-screen size (about 37pt when the prior size was 56pt); the time copy MUST sit on the trailing (right) edge. The UI MUST NOT show a trailing chevron/arrow. Event text color MUST follow the catalog color for that `eventId`, brightened when too dark against the Live Activity background tint. The push payload MUST NOT be required to carry logo URL or color hex; the client MUST resolve visuals from App Group / local catalog cache keyed by `eventId`. The client MUST NOT locally `Activity.request` (or equivalent) an Imminent Live Activity for this product path; presentation MUST wait for server push as specified by twin change `predict-live-activity-push`. Android MUST NOT be required to implement a lock-screen Live Activity in this change.

iOS 客户端 MUST 提供专用于预测临近的 Live Activity 配置（与 Timing 不同 Attributes）。系统送达 Imminent 的 Push to Start / liveactivity start 时，锁屏 MUST 为双层：上层窄行仅 App 名「胖宝」（事件提亮色），MUST NOT 在上层展示圆形 App 品牌 logo；下层宽行按 `eventId` 本地解析的事件 logo（缺失则品牌/色球兜底）、主标题（既有 `lockTitle` 语义不变），以及未过期时的右侧中文到分钟倒计时。当 `now < nextAt` 时，右侧 MUST 为「预计m分钟后」，`m` 为剩余整分钟总数（不拆时），不足 1 分钟 MUST 按 `m = 1`。当当前时间 ≥ `nextAt` 时，右侧 MUST NOT 显示「已过时」或其它时间维文案。下层事件 logo 尺寸 MUST 约为上一版双层锁屏的 2/3（上一版 56pt 时约 37pt）；时间 MUST 靠右。MUST NOT 展示右箭头。文案色 MUST 跟随该事件 catalog 色，并在相对 LA 深色底过深时提亮。推送 MUST NOT 被要求携带 logo URL 或颜色 hex；客户端 MUST 经 App Group / 本地缓存按 `eventId` 解析。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Imminent，MUST 等待对端 `predict-live-activity-push` 推送。本变更 MUST NOT 要求 Android 实现锁屏 Live Activity。

#### Scenario: Dedicated Imminent UI two-tier lock screen

- **WHEN** 系统展示一条 Imminent Live Activity 的锁屏 content
- **THEN** UI MUST 含上层「胖宝」（无圆形 App logo）、下层事件图（或兜底）、标题
- **AND** 当未过期时 MUST 在下层右侧展示「预计m分钟后」
- **AND** MUST NOT 展示右箭头
- **AND** MUST 使用与 Timing 不同的 Activity 配置

#### Scenario: Top row has no app brand mark

- **WHEN** 系统展示 Imminent 锁屏双层 content
- **THEN** 上层 MUST 含「胖宝」
- **AND** MUST NOT 展示圆形 App brand logo

#### Scenario: Event logo about two-thirds prior size

- **WHEN** Imminent 锁屏下层渲染事件 logo
- **THEN** logo 逻辑尺寸 MUST 约为先前双层锁屏 56pt 的 2/3（约 37pt）

#### Scenario: No time-dimension copy after nextAt

- **WHEN** Imminent 的 `nextAt` 不晚于当前时间且该 Live Activity 仍在展示
- **THEN** 锁屏下层右侧 MUST NOT 显示「已过时」
- **AND** MUST NOT 展示其它时间维文案（含数字倒计时）

#### Scenario: Sub-minute remaining rounds to one minute

- **WHEN** Imminent 距 `nextAt` 剩余大于 0 且不足 60 秒
- **THEN** 锁屏右侧 MUST 显示「预计1分钟后」
- **AND** MUST NOT 显示「预计0分钟后」

#### Scenario: Total minutes beyond one hour

- **WHEN** Imminent 距 `nextAt` 剩余约 90 分钟
- **THEN** 锁屏右侧 MUST 显示「预计90分钟后」
- **AND** MUST NOT 改写为带「时」的拆分文案

#### Scenario: Local visual by eventId

- **WHEN** 推送 Attributes 含有效 `eventId` 且客户端已将对应 logo/色写入 App Group 索引
- **THEN** 锁屏下层 MUST 使用该事件 logo 与（经提亮处理后的）事件色文案
- **AND** 上层 App 名 MUST 使用同一提亮事件色
- **AND** MUST NOT 要求推送 ContentState 含 logo 或 color 字段

#### Scenario: No local request for Imminent

- **WHEN** 用户本机发生喂养/预测相关变更或 App 在前台
- **THEN** 客户端 MUST NOT 仅凭本机逻辑 `Activity.request` 拉起 Imminent Live Activity

#### Scenario: Android out of scope

- **WHEN** 在 Android 上交付本变更
- **THEN** MUST NOT 要求实现锁屏 Live Activity
