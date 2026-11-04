## MODIFIED Requirements

### Requirement: iOS client SHALL present Timing Live Activity separately and only from push

For in-progress timing on iOS, the client MUST provide a Live Activity configuration separate from Imminent. The lock-screen UI MUST show: leading event logo resolved locally from `eventId` (fallback brand/orb if missing), primary title indicating timing in progress (计时中 semantics), and a trailing large-type elapsed time from `startTime` (unix seconds), vertically centered on the trailing side—not a small caption under the title. The UI MUST NOT show a trailing chevron/arrow. Event text color MUST follow the catalog color for that `eventId`, brightened when too dark against the Live Activity background tint. Timing ActivityAttributes (or equivalent fixed fields at start) MUST include `eventId` so the Extension can resolve visuals; the push MUST NOT be required to carry logo URL or color hex. The client MUST NOT locally `Activity.request` (or equivalent) a Timing Live Activity for this product path; presentation and dismissal MUST wait for server Push-to-Start / liveactivity start and end as specified by twin `predict-live-activity-push`. Multiple Timing Live Activities MUST be displayable concurrently when the system presents multiple activities.

iOS 进行中计时 MUST 使用与 Imminent 分离的 Live Activity 配置。锁屏 MUST 展示：左侧按 `eventId` 本地解析的事件 logo（缺失则品牌/色球兜底）、计时中语义主标题、右侧大字自 `startTime`（unix 秒）起的已计时（靠右垂直居中，MUST NOT 作为标题下小字）。MUST NOT 展示右箭头。文案色 MUST 跟随事件 catalog 色并在过深时提亮。Timing 起活动固定字段 MUST 含 `eventId`；推送 MUST NOT 被要求携带 logo/color。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Timing；展示与关闭 MUST 等待对端 `predict-live-activity-push` 的 start/end。系统同时下发多条时客户端 MUST 能并存展示。

#### Scenario: Separate Timing type

- **WHEN** 同时存在 Imminent 与 Timing Live Activity
- **THEN** 二者 MUST 为不同 Activity 配置，MUST NOT 用 Imminent 组件实例表达计时中

#### Scenario: Trailing large elapsed time

- **WHEN** 系统展示一条 Timing Live Activity 且 `startTime` 为有效 unix 秒
- **THEN** 锁屏 MUST 在右侧以大字展示已计时
- **AND** MUST NOT 仅在事件名下方以次要小字展示该时间
- **AND** MUST NOT 展示右箭头

#### Scenario: Local visual by eventId

- **WHEN** Timing 起活动 Attributes 含有效 `eventId` 且客户端已预置对应 App Group 视觉索引
- **THEN** 锁屏 MUST 使用该事件 logo 与（提亮后的）事件色
- **AND** MUST NOT 要求推送下发 logo 或 color

#### Scenario: No local request for Timing

- **WHEN** 用户在本机开始一条计时且 App 仍在前台
- **THEN** 客户端 MUST NOT 仅凭本地开始动作创建 Timing Live Activity

#### Scenario: Multiple Timing activities

- **WHEN** 系统同时呈现两条不同 history 对应的 Timing Live Activity
- **THEN** 客户端锁屏 MUST 允许同时展示二者
