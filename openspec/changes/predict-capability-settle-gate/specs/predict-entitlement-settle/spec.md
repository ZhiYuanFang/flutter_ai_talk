## ADDED Requirements

### Requirement: Client SHALL expose predict entitlement settle phase syncing or ready

For a logged-in bound baby session, the client SHALL treat predict commercial entitlement inputs as **syncing** until both: settled VIP status is available as `AsyncData` (including null fail-closed), and feature catalog has reached ready for the current `deviceNo` (or failed after attempt). Otherwise the phase MUST be **ready**. Unauthenticated or unbound sessions MUST NOT require syncing chrome for predict entitlement. The client MUST NOT treat the syncing phase as “not entitled” for side-effect gates that claim trial reminders.

已登录已绑定会话 MUST 在 VIP AsyncData 与 catalog ready（或失败结案）之前为 syncing；否则 ready。syncing MUST NOT 当作未开通去触发提醒副作用。

#### Scenario: 冷启动 VIP loading

- **WHEN** 用户已绑定进入预测页且 vipStatus 仍为 loading
- **THEN** 开通相位 MUST 为 syncing

#### Scenario: VIP 与 catalog 均结案

- **WHEN** vipStatus 为 AsyncData 且 catalog.ready 对应当前 deviceNo（或 catalog.failed 已结案）
- **THEN** 相位 MUST 为 ready

### Requirement: Debug CLEAR_PREDICT_ALGO_REMIND SHALL clear reminded cache only when enabled

The client SHALL read `bool.fromEnvironment('CLEAR_PREDICT_ALGO_REMIND', defaultValue: false)`. When true **and** running in debug mode (`kDebugMode`), early startup MUST clear the per-baby algorithm-ready reminded store and MUST log via `AppDebugLog`. When the define is absent or false, release/default builds MUST NOT clear that store. Release builds MUST NOT require the define for normal operation.

Debug 下 `--dart-define=CLEAR_PREDICT_ALGO_REMIND=true` MUST 清已提醒缓存；默认 false MUST 不影响打包。

#### Scenario: 默认不清除

- **WHEN** 未传 CLEAR_PREDICT_ALGO_REMIND 或为 false
- **THEN** 启动 MUST NOT 清除算法就绪已提醒标记

#### Scenario: Debug 传 true 清除

- **WHEN** kDebugMode 且 CLEAR_PREDICT_ALGO_REMIND=true
- **THEN** 启动 MUST 清除已提醒本地缓存
