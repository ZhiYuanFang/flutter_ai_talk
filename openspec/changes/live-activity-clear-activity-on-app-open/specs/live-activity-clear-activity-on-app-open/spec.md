## ADDED Requirements

### Requirement: Client MUST NOT post Live Activity update ack

The client MUST NOT decode ContentState.`ack` for delivery receipt purposes, MUST NOT observe ActivityKit content updates solely to acknowledge delivery, and MUST NOT call `POST /app/api/push/live-activity/ack` from native or Dart. Lock-screen UI MUST continue to render from `phase` / `items` (and other business fields) without depending on `ack`. 客户端 MUST NOT 再为送达回执解码或上报 `ack`；MUST NOT 调用 ack HTTP。

#### Scenario: No ack HTTP after ContentState update

- **WHEN** 统一 Live Activity 收到 ContentState 更新
- **THEN** 客户端 MUST NOT `POST /app/api/push/live-activity/ack`

#### Scenario: ContentState without ack still renders

- **WHEN** ContentState 不含 `ack` 键
- **THEN** 锁屏/Island MUST 仍按业务字段正常展示且 MUST NOT 因缺 `ack` 失败

### Requirement: App open without local Live Activity MUST clear server activity token

When the Flutter app is in a logged-in state (Bearer available) and reaches a cold-start ready point or `AppLifecycleState.resumed`, the client MUST query whether any `BabyLiveActivityAttributes` Live Activity currently exists on device via ActivityKit (through native bridge as needed). If none exists, the client MUST `POST /app/api/push/live-activity/activity/clear` with Bearer authentication and JSON body `deviceKey` equal to this device’s push/live-activity device key. If at least one such Live Activity exists, the client MUST NOT call clear for that check. If the user is not logged in, the client MUST skip clear and MUST run the check again after login becomes available. Clear MUST NOT locally start a new Live Activity. 登录态打开/回前台且本机无统一 LA 时 MUST 鉴权 clear；有 LA MUST NOT clear；未登录跳过并在登录后补跑。

#### Scenario: No local activity triggers authenticated clear

- **WHEN** 用户已登录且 App resumed（或冷启动就绪），本机无 `BabyLiveActivityAttributes` 活动
- **THEN** 客户端 MUST `POST .../app/api/push/live-activity/activity/clear`，带 Bearer 与本机 `deviceKey`

#### Scenario: Local activity present skips clear

- **WHEN** 用户已登录且 App resumed，本机仍有至少一条统一 LA
- **THEN** 客户端 MUST NOT 调用 clear

#### Scenario: Logged out skips clear

- **WHEN** App resumed 但无可用 Bearer
- **THEN** 客户端 MUST NOT 调用 clear
- **AND** 登录成功后 MUST 再执行一次有无 LA 检查（并在无 LA 时 clear）

#### Scenario: Clear does not locally start Live Activity

- **WHEN** clear 请求已发出（成功或失败）
- **THEN** 客户端 MUST NOT 因此调用 `Activity.request` 或等价本地 start

### Requirement: Clear side-effect HTTP MUST be single-flight and observable

Lifecycle or login-triggered clear MUST reuse an in-flight request for the same device key (single-flight), MUST coalesce bursty resume events within a short window, MUST NOT silently swallow errors (MUST log via approved debug/API log outlets), and MUST NOT be started unconditionally from provider construction alone. clear 副作用 HTTP MUST single-flight、短窗合并、可观测失败，MUST NOT 在 provider 创建时无条件自动连打。

#### Scenario: Concurrent resume shares one clear

- **WHEN** 短时间内多次 resumed 且均判定需 clear
- **THEN** 客户端 MUST 至多保持一次 in-flight clear（其余复用或合并），MUST NOT 无界并发连打
