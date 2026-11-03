## ADDED Requirements

### Requirement: iOS client SHALL present Imminent as a dedicated Live Activity type

On iOS, the client MUST provide an ActivityKit Live Activity configuration dedicated to predict-imminent (separate ActivityAttributes from Timing). When the system delivers a Push-to-Start / liveactivity start for Imminent, the lock-screen UI MUST show the app logo, copy indicating the event is about to occur (即将发生), and a trailing chevron/arrow. The client MUST NOT locally `Activity.request` (or equivalent) an Imminent Live Activity for this product path; presentation MUST wait for server push as specified by twin change `predict-live-activity-push`. Android MUST NOT be required to implement a lock-screen Live Activity in this change.

iOS 客户端 MUST 提供专用于预测临近的 Live Activity 配置（与 Timing 不同 Attributes）。系统送达 Imminent 的 Push to Start / liveactivity start 时，锁屏 MUST 展示 logo、即将发生语义文案与右箭头。本产品路径 MUST NOT 本地 `Activity.request`（或等价）拉起 Imminent，MUST 等待对端 change `predict-live-activity-push` 所定义的服务端推送。本变更 MUST NOT 要求 Android 实现锁屏 Live Activity。

#### Scenario: Dedicated Imminent UI

- **WHEN** 系统展示一条 Imminent Live Activity
- **THEN** UI MUST 含 logo、即将发生语义与右箭头，且 MUST 使用与 Timing 不同的 Activity 配置

#### Scenario: No local request for Imminent

- **WHEN** 用户本机发生喂养/预测相关变更或 App 在前台
- **THEN** 客户端 MUST NOT 仅凭本机逻辑 `Activity.request` 拉起 Imminent Live Activity

#### Scenario: Android out of scope

- **WHEN** 在 Android 上交付本变更
- **THEN** MUST NOT 要求实现锁屏 Live Activity

### Requirement: Imminent tap SHALL open prediction without client dismiss

Tapping an Imminent Live Activity MUST open the app to the prediction surface (same outcome family as consuming `predict_imminent`). The Flutter/iOS client MUST NOT end or dismiss that Imminent Live Activity solely because of the tap; dismissal MUST rely on server-driven Live Activity end pushes from twin `predict-live-activity-push` (e.g. pending clear or slot replace).

点击 Imminent Live Activity MUST 打开 App 并进入预测页族表面。客户端 MUST NOT 仅因点击 end/dismiss 该条；消除 MUST 依赖对端 `predict-live-activity-push` 的服务端 end 推送（如 pending 清场或单槽换新）。

#### Scenario: Tap opens prediction

- **WHEN** 用户点击 Imminent Live Activity
- **THEN** App MUST 打开并进入预测相关主页表面
- **AND** 客户端 MUST NOT 仅因该点击结束该 Live Activity

### Requirement: Client SHALL register Live Activity tokens via live-activity register API

The iOS client MUST register Push-to-Start and per-activity update tokens via `POST /app/api/push/live-activity/register` (Bearer, same login gate family as global push), with body fields `deviceKey`, `tokenKind` (`push_to_start` or `activity`), `attributesKind` (`imminent` or `timing`), and `token`. When `tokenKind` is `activity`, `activityId` MUST be non-empty. The client MUST register Push-to-Start for both `imminent` and `timing` attributes kinds when Live Activities are enabled. The client MUST NOT send Live Activity tokens through `POST /app/api/push/register`. Failure to register MUST NOT crash the app; new debug tags MUST follow the project whitelist triple update.

iOS 客户端 MUST 经 `POST /app/api/push/live-activity/register` 上报 Push-to-Start 与 per-activity update token（字段同上）；`activity` 时 `activityId` MUST 非空；启用时 MUST 分别为 `imminent` 与 `timing` 上报 Push-to-Start。MUST NOT 经 `/app/api/push/register` 上报 LA token。失败 MUST NOT 崩溃；新日志 tag MUST 三联改。

#### Scenario: Push-to-Start register for imminent

- **WHEN** 已登录用户在支持的 iOS 上取得 Imminent 的 Push-to-Start token
- **THEN** 客户端 MUST `POST /app/api/push/live-activity/register` 且 `tokenKind=push_to_start`、`attributesKind=imminent`

#### Scenario: Activity update token after start

- **WHEN** 系统已拉起某 Timing（或 Imminent）Live Activity 且客户端拿到 per-activity update token
- **THEN** 客户端 MUST 再注册 `tokenKind=activity`、对应 `attributesKind` 与非空 `activityId`

#### Scenario: Must not use device push register

- **WHEN** 客户端上报任意 Live Activity token
- **THEN** 请求 path MUST 为 `/app/api/push/live-activity/register`，MUST NOT 为 `/app/api/push/register`
