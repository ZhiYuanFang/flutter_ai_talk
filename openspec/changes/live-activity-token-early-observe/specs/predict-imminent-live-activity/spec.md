## ADDED Requirements

### Requirement: iOS client SHALL start ActivityKit token observation early in process lifetime

On iOS, the client MUST begin observing ActivityKit Push-to-Start and per-activity push token updates early in the app process lifetime (for example during `application(_:didFinishLaunchingWithOptions:)` or an equivalent launch hook that runs before Dart `startListening` is required), for both `imminent` and `timing` attributes kinds when the OS version supports the corresponding APIs. The client MUST NOT require a successful Flutter/Dart `startListening` call as the sole prerequisite to attach these observers for the first time. Native observation MAY run while the user is logged out; HTTP registration MUST still require the existing logged-in Bearer/`deviceKey` gate and MUST use `POST /app/api/push/live-activity/register` only. The client MUST NOT locally `Activity.request` Live Activities for this product path.

iOS 客户端 MUST 在进程生命周期早期开始观察 ActivityKit 的 Push-to-Start 与 per-activity push token（在 OS 支持的前提下覆盖 `imminent` 与 `timing`），MUST NOT 把 Dart `startListening` 成功当作首次挂观察的唯一前提。未登录时 MAY 继续原生观察；HTTP 上报 MUST 仍受既有登录门闸约束且 MUST 仅走 `live-activity/register`。MUST NOT 对本产品路径本地 `Activity.request`。

#### Scenario: Observation starts without waiting for Dart startListening

- **WHEN** iOS 主 App 进程完成启动钩子（如 `didFinishLaunching`）且系统版本支持对应 ActivityKit token API
- **THEN** 客户端 MUST 已开始（或已调度开始）对 Imminent / Timing 的 Push-to-Start 与 per-activity token 观察
- **AND** MUST NOT 以「Dart 尚未调用 `startListening`」为由拒绝首次挂观察

#### Scenario: Logout does not require native HTTP register

- **WHEN** 用户未登录且原生已收到某 Live Activity token 事件
- **THEN** 客户端 MUST NOT 在无有效登录会话时对该 token 成功完成 `POST /app/api/push/live-activity/register`
- **AND** MAY 将事件暂存直至登录后由既有 register 管线处理

### Requirement: iOS client SHALL backfill push token observers for already-running Live Activities

Whenever the iOS client starts or restarts ActivityKit token observation for an attributes kind, it MUST enumerate currently active Live Activities of that kind (e.g. `Activity<Attributes>.activities`) and subscribe to each activity’s `pushTokenUpdates` (or equivalent) so that per-activity update tokens for already-presented lock-screen activities can be delivered to the existing Dart register pipeline. Relying solely on future `activityUpdates` emissions MUST NOT be treated as sufficient for activities that already exist when observation begins.

每当 iOS 客户端开始或重启某 attributes 类型的 token 观察时，MUST 枚举该类型当前已活跃的 Live Activity 并为每一条订阅 `pushTokenUpdates`（或等价 API），以便已在锁屏展示的实例仍能把 per-activity token 交给既有 Dart register 管线。MUST NOT 仅依赖之后的 `activityUpdates` 作为「观察开始时已存在」实例的充分覆盖。

#### Scenario: Cold start while Live Activity already on lock screen

- **WHEN** 系统已在锁屏展示一条 Imminent 或 Timing Live Activity，且用户随后打开 App 使客户端完成（或重启）token 观察
- **THEN** 客户端 MUST 对该已存在 activity 订阅其 per-activity push token 更新
- **AND** 当拿到非空 `activityId` 的 update token 且用户已登录时，MUST `POST /app/api/push/live-activity/register` 且 `tokenKind=activity`

#### Scenario: Background wake after Push-to-Start

- **WHEN** App 原先未在前台，系统因 Push-to-Start 拉起 Live Activity 并唤醒主 App 进程，且早期观察已挂上
- **THEN** 客户端 MUST 能经 `activityUpdates` 与/或已有 activities 补扫路径接收该实例的 per-activity token
- **AND** 在 Dart 与登录门闸就绪后 MUST 尝试 `tokenKind=activity` 的 `live-activity/register`

### Requirement: iOS Live Activity tokens SHALL be queued when Dart is not yet ready to receive

When ActivityKit delivers a Push-to-Start or per-activity token and the Live Activity MethodChannel is missing or Dart has not yet declared readiness to receive token events, the native side MUST retain the token event in an in-process pending inbox (deduplicated by a stable identity including at least `tokenKind`, `attributesKind`, `activityId` when present, and `token`) and MUST flush pending events to Dart once the channel is available and Dart is listening. The client MUST NOT treat “no channel / Dart not listening” as a permanent drop of that token for the current process. Successful HTTP registration remains the responsibility of the existing Dart `live-activity/register` pipeline and MUST apply success-identity skip / single-flight style guards so early observe plus backfill do not spam duplicate POSTs for an unchanged token identity. The client MUST NOT log raw tokens.

当 ActivityKit 吐出 Push-to-Start 或 per-activity token 且 MethodChannel 缺失或 Dart 尚未声明可收时，原生 MUST 将该事件保留在进程内 pending inbox（至少按 `tokenKind`、`attributesKind`、有则 `activityId`、`token` 去重），并在 channel 可用且 Dart 可收后 flush。MUST NOT 将「无 channel / Dart 未听」视为本进程对该 token 的永久丢弃。成功 HTTP 仍由既有 Dart `live-activity/register` 管线负责，且 MUST 对不变的成功身份做跳过/单飞类防护，避免 early observe 与补扫重复打 POST。MUST NOT 打印原始 token。

#### Scenario: Token arrives before Dart startListening

- **WHEN** 原生已收到 `tokenKind=activity`（或 `push_to_start`）事件但 Dart 尚未 `startListening` / 未绑定可收 handler
- **THEN** 原生 MUST 将事件暂存于 inbox 而非静默丢弃
- **AND WHEN** Dart 随后声明可收
- **THEN** 客户端 MUST flush 该事件并（在已登录时）进入既有 register 尝试

#### Scenario: Duplicate identity skipped after successful register

- **WHEN** 客户端已对某一 `deviceKey + tokenKind + attributesKind + activityId? + token` 身份成功 `live-activity/register`
- **AND** 同一身份因补扫或重复 `pushTokenUpdates` 再次到达
- **THEN** 客户端 MUST 跳过重复 POST（或等价不再发起无变更的 register）
- **AND** MUST NOT 因此崩溃或阻断后续不同身份的 token 上报
