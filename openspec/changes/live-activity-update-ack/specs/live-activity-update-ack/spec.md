## ADDED Requirements

### Requirement: ContentState SHALL decode optional ack alongside phase and items

The iOS unified Live Activity ContentState (`BabyLiveActivityAttributes.ContentState`) MUST decode an optional opaque string field `ack` that arrives in the same APNs update ContentState payload as `phase` and `items` (twin Go injects `ack` only on `event=update`). Missing or empty `ack` MUST decode to an empty value without failing the whole ContentState. Lock-screen and Dynamic Island UI MUST ignore `ack` for rendering. ContentState 必须解码与 phase/items 同包下发的可选 `ack`；缺省不得导致解码失败；UI 必须忽略该字段。

#### Scenario: Update payload with ack decodes

- **WHEN** 系统向统一 Live Activity 投递 ContentState 含非空 `ack` 与 `items`
- **THEN** 客户端 MUST 成功解码 `ack` 为该非空字符串
- **AND** 锁屏/Island MUST 仍仅按 `items`/`phase` 展示，MUST NOT 因 `ack` 改变视觉

#### Scenario: Start or end without ack still decodes

- **WHEN** ContentState 缺少 `ack` 键或 `ack` 为空
- **THEN** 客户端 MUST 将 `ack` 视为空且 MUST NOT 因缺键抛错或拒绝更新

### Requirement: iOS native SHALL POST live-activity ack when ContentState ack is non-empty

When the main app Runner observes a ContentState update (including reading the current `activity.content.state` when attaching an observer) for `BabyLiveActivityAttributes` and the decoded `ack` is non-empty, the iOS **native** layer MUST immediately `POST /app/api/push/live-activity/ack` with JSON body fields `wxId` (non-zero, from the same cached register context as live-activity register), `deviceKey`, and `ack` equal to that ContentState value. The request MUST NOT require Bearer/JWT. The client MUST NOT implement Dart/Flutter supplemental transmission of this ack. Failure to POST MUST NOT crash the app. Empty `ack` MUST NOT trigger the request. 主 App 原生在 ContentState.`ack` 非空时 MUST 立即免鉴权 POST ack；MUST NOT 经 Dart 补传；空 ack MUST NOT 请求；失败 MUST NOT 崩溃。

#### Scenario: Non-empty ack triggers native POST

- **WHEN** ActivityKit 向 Runner 交付统一 LA 的 ContentState 且 `ack` 非空，且本地已缓存非零 `wxId`、非空 `deviceKey` 与 apiBase
- **THEN** 原生 MUST `POST .../app/api/push/live-activity/ack`，body 含该 `wxId`、`deviceKey` 与同一 `ack`
- **AND** MUST NOT 依赖 Flutter 引擎已启动或 MethodChannel 投递

#### Scenario: Empty ack does not POST

- **WHEN** ContentState 更新且 `ack` 为空或缺失
- **THEN** 客户端 MUST NOT 调用 `live-activity/ack`

#### Scenario: No Dart supplemental ack path

- **WHEN** 任意 Live Activity ContentState 含非空 `ack`
- **THEN** 客户端 MUST NOT 要求 Dart 侧再发一次 ack 补传作为成功条件

#### Scenario: Missing register context skips without crash

- **WHEN** ContentState.`ack` 非空但本地无可用 `wxId` 或 `deviceKey` 或 apiBase
- **THEN** 原生 MUST 跳过本次 POST 且 MUST NOT 崩溃
