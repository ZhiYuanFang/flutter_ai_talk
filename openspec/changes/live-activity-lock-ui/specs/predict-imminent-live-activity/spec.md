## MODIFIED Requirements

### Requirement: iOS client SHALL present Imminent as a dedicated Live Activity type

On iOS, the client MUST provide an ActivityKit Live Activity configuration dedicated to predict-imminent (separate ActivityAttributes from Timing). When the system delivers a Push-to-Start / liveactivity start for Imminent, the lock-screen UI MUST show: leading event logo resolved locally from `eventId` (fallback brand/orb if missing), primary title copy, and a trailing large-type countdown to `nextAt`. When current time is at or after `nextAt`, the trailing slot MUST show the fixed copy「已过时」instead of a negative countdown. The UI MUST NOT show a trailing chevron/arrow. Event text color MUST follow the catalog color for that `eventId`, brightened when too dark against the Live Activity background tint. The push payload MUST NOT be required to carry logo URL or color hex; the client MUST resolve visuals from App Group / local catalog cache keyed by `eventId`. The client MUST NOT locally `Activity.request` (or equivalent) an Imminent Live Activity for this product path; presentation MUST wait for server push as specified by twin change `predict-live-activity-push`. Android MUST NOT be required to implement a lock-screen Live Activity in this change.

iOS 客户端 MUST 提供专用于预测临近的 Live Activity 配置（与 Timing 不同 Attributes）。系统送达 Imminent 的 Push to Start / liveactivity start 时，锁屏 MUST 展示：左侧按 `eventId` 本地解析的事件 logo（缺失则品牌/色球兜底）、主标题、右侧大字距 `nextAt` 倒计时；当当前时间 ≥ `nextAt` 时，右侧 MUST 显示「已过时」而非负计时。MUST NOT 展示右箭头。文案色 MUST 跟随该事件 catalog 色，并在相对 LA 深色底过深时提亮。推送 MUST NOT 被要求携带 logo URL 或颜色 hex；客户端 MUST 经 App Group / 本地缓存按 `eventId` 解析。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Imminent，MUST 等待对端 `predict-live-activity-push` 推送。本变更 MUST NOT 要求 Android 实现锁屏 Live Activity。

#### Scenario: Dedicated Imminent UI

- **WHEN** 系统展示一条 Imminent Live Activity
- **THEN** UI MUST 含左侧事件图（或兜底）、标题与右侧倒计时或「已过时」
- **AND** MUST NOT 展示右箭头
- **AND** MUST 使用与 Timing 不同的 Activity 配置

#### Scenario: Overdue copy after nextAt

- **WHEN** Imminent 的 `nextAt` 不晚于当前时间且该 Live Activity 仍在展示
- **THEN** 右侧时间位 MUST 显示「已过时」
- **AND** MUST NOT 继续展示负向倒计时数字

#### Scenario: Local visual by eventId

- **WHEN** 推送 Attributes 含有效 `eventId` 且客户端已将对应 logo/色写入 App Group 索引
- **THEN** 锁屏 MUST 使用该事件 logo 与（经提亮处理后的）事件色文案
- **AND** MUST NOT 要求推送 ContentState 含 logo 或 color 字段

#### Scenario: No local request for Imminent

- **WHEN** 用户本机发生喂养/预测相关变更或 App 在前台
- **THEN** 客户端 MUST NOT 仅凭本机逻辑 `Activity.request` 拉起 Imminent Live Activity

#### Scenario: Android out of scope

- **WHEN** 在 Android 上交付本变更
- **THEN** MUST NOT 要求实现锁屏 Live Activity
