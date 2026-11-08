## MODIFIED Requirements

### Requirement: iOS client SHALL present Imminent as a dedicated Live Activity type

On iOS, predict-imminent content MUST appear as `kind=imminent` rows inside the unified `BabyLiveActivityAttributes` Live Activity defined by `unified-live-activity`, and MUST NOT use a separate `PredictImminentAttributes` ActivityConfiguration on the product path. When an imminent item is rendered on the lock screen, the row MUST reuse the existing Imminent row chrome: leading event logo resolved locally from `eventId` (fallback brand/orb), primary title from `title` (empty fallback such as「事件即将发生」MAY remain), and trailing short structured expect copy when usable — MUST NOT show nextAt-based time-dimension copy（「预计m分钟后」、到 `nextAt` 的数字倒计时、「已过时」）. Logo size and accent rules for the row MUST remain as before. Push MUST NOT be required to carry logo/color. The product path MUST NOT locally `Activity.request` Imminent; display MUST wait for twin unified Refresh push. This requirement MUST NOT require Android lock-screen Live Activity.

iOS 预测临近内容 MUST 作为统一 LA 的 `kind=imminent` 行展示，MUST NOT 再使用独立 `PredictImminentAttributes`。锁屏行 MUST 复用既有 Imminent 行样式与 expect 右槽语义，MUST NOT 展示基于 nextAt 的时间维文案。MUST NOT 本地 request；MUST NOT 要求 Android LA。

#### Scenario: Imminent as list row

- **WHEN** 统一 ContentState `items` 含 `kind=imminent` 且无可用 expect
- **THEN** 锁屏 MUST 渲染该行 logo+标题且右槽为空，MUST NOT 使用独立 Imminent Activity 类型

#### Scenario: Expect trailing preserved

- **WHEN** imminent 项含可用 `expectKind=duration` 或 `amount`
- **THEN** 该行右侧 MUST 仍按既有短版预计文案展示（字号相对 Timing 已计时基准 −5pt）

#### Scenario: No nextAt countdown on row

- **WHEN** imminent 项的 `nextAt` 仍晚于当前时间且该行在展示
- **THEN** 该行 MUST NOT 展示到 `nextAt` 的数字倒计时或「预计m分钟后」

### Requirement: Client SHALL register Live Activity tokens via live-activity register API

The iOS client MUST register Push-to-Start and per-activity update tokens via `POST /app/api/push/live-activity/register` with body fields `wxId` (non-zero), `deviceKey`, `tokenKind` (`push_to_start` or `activity`), and `token`, per `unified-live-activity`. The client MUST NOT send `attributesKind` of `imminent` or require `activityId` for slotting. Successful registration MUST NOT require Bearer/JWT. The client MUST NOT send Live Activity tokens through `POST /app/api/push/register`. Failure MUST NOT crash the app; new debug tags MUST follow the project whitelist triple update.

iOS 客户端 MUST 经统一 register 契约上报；MUST NOT 再传 `attributesKind=imminent` 或分槽 `activityId`；MUST NOT 经 `/app/api/push/register` 上报 LA token。

#### Scenario: Push-to-start without attributesKind

- **WHEN** 已登录用户收到统一 Attributes 的 Push-to-Start token 且本地有非零 wxId
- **THEN** 客户端 MUST `POST /app/api/push/live-activity/register` 且 body 含该 wxId、`tokenKind=push_to_start`，MUST NOT 依赖 `attributesKind=imminent`

#### Scenario: Activity token without activityId slot

- **WHEN** 系统已拉起统一 Live Activity 且客户端拿到 activity update token 与非零缓存 wxId
- **THEN** 客户端 MUST 再注册 `tokenKind=activity` 与该 wxId，MUST NOT 要求非空 `activityId` 分槽

#### Scenario: Not via device push register

- **WHEN** 客户端上报任意 Live Activity token
- **THEN** 请求 path MUST 为 `/app/api/push/live-activity/register`，MUST NOT 为 `/app/api/push/register`

### Requirement: Imminent Dynamic Island SHALL NOT show time-dimension copy

When the unified Live Activity’s Dynamic Island is driven by `items.first` with `kind=imminent`, compact and expanded trailing MUST NOT show nextAt-based time-dimension copy or expect trailing copy. Behavior MUST match the prior Imminent-only Island（无时间维 / 无 expect 右槽）. When `items.first` is not imminent, this requirement MUST NOT force Island chrome. 当 Island 由首条 imminent 驱动时 MUST NOT 展示时间维或 expect；首条非 imminent 时本条 MUST NOT 强改 Island。

#### Scenario: First item imminent

- **WHEN** `items[0].kind=imminent` 且以 Dynamic Island compact 或 expanded 展示
- **THEN** trailing MUST 为空（或不含 nextAt 倒计时 / expect 文案）

### Requirement: iOS Live Activity tokens SHALL be queued when Dart is not yet ready to receive

When ActivityKit delivers a Push-to-Start or per-activity token and the client elects to also deliver the event to Dart, if the Live Activity MethodChannel is missing or Dart has not yet declared readiness, the native side MUST retain the token event in an in-process pending inbox (deduplicated by a stable identity including at least `tokenKind` and `token`, and MUST NOT require `attributesKind`/`activityId` in that identity) and MUST flush pending events to Dart once the channel is available and Dart is listening. Native HTTP registration using cached `wxId` MUST NOT wait for Dart readiness. The client MUST NOT log raw tokens.

当 ActivityKit 吐出 token 且需投递 Dart 时，若 channel/Dart 未就绪，原生 MUST 进程内 inbox 暂存（去重身份至少含 `tokenKind`+`token`，MUST NOT 再依赖 attributesKind/activityId），就绪后 flush；原生 HTTP MUST NOT 等 Dart；MUST NOT 打原始 token。

#### Scenario: Queue then flush

- **WHEN** Push-to-Start token 到达时 Dart 尚未 `startListening`
- **THEN** 原生 MUST 暂存该事件，并在 Dart 可收后 flush，且去重身份 MUST NOT 要求 `attributesKind`

#### Scenario: Success identity without dual slots

- **WHEN** 客户端已对某一 `wxId + deviceKey + tokenKind + token` 身份成功 `live-activity/register`
- **THEN** 相同身份的后续自动上报 MUST 可幂等跳过（MUST NOT 再把 attributesKind/activityId 当作必需身份维）

### Requirement: Server twin SHALL accept live-activity register without Bearer using body wxId

The `go_ai_talk` twin for `POST /app/api/push/live-activity/register` MUST NOT require Bearer/JWT interception for a successful upsert. The handler MUST require a non-zero `wxId` in the request body and MUST persist or update the Live Activity token against that `wxId` together with `deviceKey` / `tokenKind` / `token` under the unified (no attributesKind/activityId slot) contract. This Flutter-repo change MUST document the twin contract; implementing the Go gateway/handler lives in the twin repo.

对端 twin MUST 免 Bearer 并按 body.`wxId` 落库；统一契约 MUST NOT 再要求 attributesKind/activityId 分槽。本仓 MUST 文档化契约；Go 实现在 twin 仓。

#### Scenario: Documented unified register

- **WHEN** 客户端按统一 body 上报（无 attributesKind/activityId）
- **THEN** 契约文档 MUST 标明 twin 接受该 body 且不以分槽字段为成功前置条件
