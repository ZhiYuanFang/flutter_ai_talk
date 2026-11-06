## MODIFIED Requirements

### Requirement: Client SHALL register Live Activity tokens via live-activity register API

The iOS client MUST register Push-to-Start and per-activity update tokens via `POST /app/api/push/live-activity/register` with body fields `wxId` (non-zero), `deviceKey`, `tokenKind` (`push_to_start` or `activity`), `attributesKind` (`imminent` or `timing`), and `token`. When `tokenKind` is `activity`, `activityId` MUST be non-empty. Successful registration MUST NOT require a Bearer/JWT access token on this path (the server twin MUST accept the request without token auth interception and MUST persist tokens against body `wxId`). The client MUST register Push-to-Start for both `imminent` and `timing` attributes kinds when Live Activities are enabled. The client MUST NOT send Live Activity tokens through `POST /app/api/push/register`. Failure to register MUST NOT crash the app; new debug tags MUST follow the project whitelist triple update.

iOS 客户端 MUST 经 `POST /app/api/push/live-activity/register` 上报 Push-to-Start 与 per-activity update token；body MUST 含非零 `wxId` 以及既有 `deviceKey` / `tokenKind` / `attributesKind` / `token`；`activity` 时 `activityId` MUST 非空。该 path 成功落库 MUST NOT 依赖 Bearer/JWT（对端 twin MUST 不做 token 鉴权拦截，并按 body.`wxId` 持久化）。启用时 MUST 分别为 `imminent` 与 `timing` 上报 Push-to-Start。MUST NOT 经 `/app/api/push/register` 上报 LA token。失败 MUST NOT 崩溃；新日志 tag MUST 三联改。

#### Scenario: Push-to-Start register for imminent

- **WHEN** 客户端在支持的 iOS 上取得 Imminent 的 Push-to-Start token 且本地有非零缓存 `wxId`
- **THEN** 客户端 MUST `POST /app/api/push/live-activity/register` 且 body 含该 `wxId`、`tokenKind=push_to_start`、`attributesKind=imminent`
- **AND** MUST NOT 以缺少 Bearer 为由拒绝发起该请求

#### Scenario: Activity update token after start

- **WHEN** 系统已拉起某 Timing（或 Imminent）Live Activity 且客户端拿到 per-activity update token 与非空 `activityId`，且本地有非零缓存 `wxId`
- **THEN** 客户端 MUST 再注册 `tokenKind=activity`、对应 `attributesKind`、非空 `activityId` 与该 `wxId`

#### Scenario: Must not use device push register

- **WHEN** 客户端上报任意 Live Activity token
- **THEN** 请求 path MUST 为 `/app/api/push/live-activity/register`，MUST NOT 为 `/app/api/push/register`

### Requirement: iOS client SHALL start ActivityKit token observation early in process lifetime

On iOS, the client MUST begin observing ActivityKit Push-to-Start and per-activity push token updates early in the app process lifetime (for example during `application(_:didFinishLaunchingWithOptions:)` or an equivalent launch hook that runs before Dart `startListening` is required), for both `imminent` and `timing` attributes kinds when the OS version supports the corresponding APIs. The client MUST NOT require a successful Flutter/Dart `startListening` call as the sole prerequisite to attach these observers for the first time. Native observation MAY run while no `wxId` is cached; HTTP registration on the native path MUST require a non-zero cached `wxId` and MUST use `POST /app/api/push/live-activity/register` only (without requiring Bearer). The client MUST NOT locally `Activity.request` Live Activities for this product path.

iOS 客户端 MUST 在进程生命周期早期开始观察 ActivityKit 的 Push-to-Start 与 per-activity push token（在 OS 支持的前提下覆盖 `imminent` 与 `timing`），MUST NOT 把 Dart `startListening` 成功当作首次挂观察的唯一前提。无缓存 `wxId` 时 MAY 继续原生观察；原生 HTTP 上报 MUST 在有非零缓存 `wxId` 时走 `live-activity/register` 且 MUST NOT 要求 Bearer。MUST NOT 对本产品路径本地 `Activity.request`。

#### Scenario: Observation starts without waiting for Dart startListening

- **WHEN** iOS 主 App 进程完成启动钩子（如 `didFinishLaunching`）且系统版本支持对应 ActivityKit token API
- **THEN** 客户端 MUST 已开始（或已调度开始）对 Imminent / Timing 的 Push-to-Start 与 per-activity token 观察
- **AND** MUST NOT 以「Dart 尚未调用 `startListening`」为由拒绝首次挂观察

#### Scenario: No cached wxId skips register without requiring Bearer session

- **WHEN** 本地无非零缓存 `wxId` 且原生已收到某 Live Activity token 事件
- **THEN** 客户端 MUST NOT 对该 token 成功完成 `POST /app/api/push/live-activity/register`
- **AND** MUST NOT 因缺少 Bearer/登录壳而额外阻塞「有 wxId 时」的原生 register 路径

### Requirement: iOS client SHALL backfill push token observers for already-running Live Activities

Whenever the iOS client starts or restarts ActivityKit token observation for an attributes kind, it MUST enumerate currently active Live Activities of that kind (e.g. `Activity<Attributes>.activities`) and subscribe to each activity’s `pushTokenUpdates` (or equivalent) so that per-activity update tokens for already-presented lock-screen activities can reach the native (and optional Dart) register pipeline. Relying solely on future `activityUpdates` emissions MUST NOT be treated as sufficient for activities that already exist when observation begins. The client MUST NOT treat “user opened the app” as a required automatic catch-up step for uploading activity tokens that were missed while the app was not running.

每当 iOS 客户端开始或重启某 attributes 类型的 token 观察时，MUST 枚举该类型当前已活跃的 Live Activity 并为每一条订阅 `pushTokenUpdates`（或等价 API），以便已在锁屏展示的实例仍能把 per-activity token 交给原生（及可选 Dart）register 管线。MUST NOT 仅依赖之后的 `activityUpdates` 作为「观察开始时已存在」实例的充分覆盖。MUST NOT 将「用户打开 App」作为补报遗漏 activity token 的必需自动步骤。

#### Scenario: Background wake after Push-to-Start registers without opening UI

- **WHEN** App 原先未在前台，系统因 Push-to-Start 拉起 Live Activity 并唤醒主 App 进程，早期观察已挂上，且本地有非零缓存 `wxId`
- **THEN** 客户端 MUST 能经 `activityUpdates` 与/或已有 activities 补扫路径接收该实例的 per-activity token
- **AND** 原生 MUST 尝试 `tokenKind=activity` 的 `live-activity/register`（含该 `wxId`），MUST NOT 以用户未打开 App UI 或 Dart 未登录为由跳过

#### Scenario: Open app is not a required activity-token catch-up

- **WHEN** 系统已在锁屏展示 Live Activity 且 activity token 因故未上报，用户随后仅打开 App（无新的 ActivityKit token 事件）
- **THEN** 客户端 MUST NOT 被本规格要求仅为补报该 activity token 而自动 `restartListening` 或等价强制补扫上报
- **AND** 设置页手动重试 MAY 仍触发重新监听（排障，非自动兜底）

### Requirement: iOS Live Activity tokens SHALL be queued when Dart is not yet ready to receive

When ActivityKit delivers a Push-to-Start or per-activity token and the client elects to also deliver the event to Dart, if the Live Activity MethodChannel is missing or Dart has not yet declared readiness, the native side MUST retain the token event in an in-process pending inbox (deduplicated by a stable identity including at least `tokenKind`, `attributesKind`, `activityId` when present, and `token`) and MUST flush pending events to Dart once the channel is available and Dart is listening. Native HTTP registration using cached `wxId` MUST NOT wait for Dart readiness. Successful HTTP registration on the wake path is the responsibility of the native register pipeline (Dart MAY also POST under the same contract with success-identity skip). The client MUST NOT log raw tokens.

当 ActivityKit 吐出 token 且客户端仍选择投递给 Dart 时，若 MethodChannel 缺失或 Dart 尚未声明可收，原生 MUST 将事件保留在进程内 pending inbox（至少按 `tokenKind`、`attributesKind`、有则 `activityId`、`token` 去重），并在 channel 可用且 Dart 可收后 flush。使用缓存 `wxId` 的原生 HTTP 上报 MUST NOT 等待 Dart 就绪。唤醒路径上的成功 HTTP 由原生 register 管线负责（Dart MAY 按同契约 POST 并做成身份跳过）。MUST NOT 打印原始 token。

#### Scenario: Native register does not wait for Dart

- **WHEN** 原生已收到 `tokenKind=activity`（或 `push_to_start`）且本地有非零缓存 `wxId`
- **THEN** 原生 MUST 可在 Dart 尚未 `startListening` 时发起 `live-activity/register`
- **AND** MUST NOT 仅因 Dart 未就绪而永久放弃该次原生上报尝试

#### Scenario: Duplicate identity skipped after successful register

- **WHEN** 客户端已对某一 `wxId + deviceKey + tokenKind + attributesKind + activityId? + token` 身份成功 `live-activity/register`
- **AND** 同一身份因重复 `pushTokenUpdates` 或 Dart 补传再次到达
- **THEN** 客户端 MUST 跳过重复 POST（或等价不再发起无变更的 register）
- **AND** MUST NOT 因此崩溃或阻断后续不同身份的 token 上报

## ADDED Requirements

### Requirement: iOS client SHALL cache wxId for native Live Activity register

On iOS, when the user completes a successful login (or session refresh) that yields a non-zero `wxId`, the client MUST persist that `wxId` in storage readable by native code during background wake (e.g. Keychain with accessibility suitable for post-unlock background execution). On logout or hard session invalidation, the client MUST clear the cached `wxId`. Native Live Activity register MUST read this cache and MUST NOT invent a `wxId`. The client MUST NOT store access/refresh tokens in native solely for Live Activity register.

iOS 上，当用户成功登录（或会话刷新）得到非零 `wxId` 时，客户端 MUST 将 `wxId` 持久化到原生在后台唤醒时可读取的存储（如合适 accessibility 的 Keychain）。登出或硬失效时 MUST 清除缓存 `wxId`。原生 LA register MUST 读该缓存且 MUST NOT 伪造 `wxId`。MUST NOT 仅为 LA register 在原生侧存储 access/refresh token。

#### Scenario: Login writes wxId for native

- **WHEN** 用户登录成功且 JWT（或等价）含非零 `wxId`
- **THEN** 客户端 MUST 将非零 `wxId` 写入原生可读缓存

#### Scenario: Logout clears wxId

- **WHEN** 用户登出或会话硬失效
- **THEN** 客户端 MUST 清除原生可读的缓存 `wxId`
- **AND** 此后原生收到 LA token 时 MUST NOT 再成功完成带旧 `wxId` 的 register

### Requirement: Server twin SHALL accept live-activity register without Bearer using body wxId

The `go_ai_talk` twin for `POST /app/api/push/live-activity/register` MUST NOT require Bearer/JWT interception for a successful upsert. The handler MUST require a non-zero `wxId` in the request body and MUST persist or update the Live Activity token fields against that `wxId` (together with existing `deviceKey` / `tokenKind` / `attributesKind` / `token` / `activityId` rules). This Flutter-repo change MUST document the twin contract; implementing the Go gateway/handler lives in the twin repo.

对端 `go_ai_talk` 对 `POST /app/api/push/live-activity/register` MUST NOT 将 Bearer/JWT 作为成功 upsert 的前置条件。Handler MUST 要求 body 非零 `wxId`，并按该 `wxId`（连同既有字段规则）持久化或更新 Live Activity token。本仓 MUST 文档化 twin 契约；Go 网关/handler 实现落在 twin 仓。

#### Scenario: Unauthenticated register with wxId succeeds at contract level

- **WHEN** 客户端（含原生唤醒路径）在无 Bearer 的情况下 POST 合法 body（含非零 `wxId` 与既有必填字段）
- **THEN** 对端契约 MUST 允许将该 token 落到该 `wxId` 名下
- **AND** MUST NOT 仅因缺少 Authorization 头而拒绝该业务落库（twin 实现后）
