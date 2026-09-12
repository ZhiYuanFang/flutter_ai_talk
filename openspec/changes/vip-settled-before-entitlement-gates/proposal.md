## Why

预测页与其它权益闸门用 `vipStatusProvider.valueOrNull?.isVip == true` 把 **loading/未知** 当成非 VIP；care-alert 等副作用 ensure 在 VIP 未 settled 时按未开通 skip daily，且 VIP 晚到后不自动补拉。同时 `SmartPredictionScreen.build` 内调用 `featureCatalog.ensureLoaded()` 在 build 期间改 provider，触发 Riverpod 断言。需要 **一处 VIP settle 契约**，让后续所有依赖 `isVip` 的判断遵循同一规则，而不是每个页面再抄一套生命周期适配；且 **不得** 用 await 拉长启动遮罩。

## What Changes

- 引入共享 **`ensureVipSettled`**（single-flight）：副作用路径在读取 `isVip` 并据此分支 HTTP/跳过前 MUST await；已有 settled 结果则秒回。
- 约定：后续新增「用 VIP 覆盖/闸门」的功能 **MUST** 走该 API（或等价 settled 读），不得在 Widget `build` 里 kick/await VIP，不得把 AsyncLoading 当非 VIP 做副作用决定。
- care-alert `ensureLoaded`：在 catalog 开通判定前 await VIP settled。
- 可选：`GatewayBootstrapGate` 登录后预热 VIP（kick，不堵 Splash）。
- 删除 `SmartPredictionScreen` build 内 `featureCatalog.ensureLoaded()`；catalog 仍由壳层进预测页 ensure。
- **不** 在启动遮罩 / `_runColdStart` 上 await `vip/status`。
- 不新建 `**/test/**`。

## Capabilities

### New Capabilities

- `vip-status-settlement`：VIP status settle 共享契约、副作用门闸规则、禁止 Splash await、禁止 build 副作用 kick。

### Modified Capabilities

- `feature-entitlement-client`：有效开通判定所用 `isVip` MUST 来自已 settled 的 VIP 状态（副作用路径）。
- `llm-care-alert-daily`：日列表 ensure 在按 VIP/catalog 开通门闸分支前 MUST await VIP settled。
- `smart-prediction-page`：预测页 build MUST NOT 同步触发 catalog ensure（改 provider）。

## Impact

- `app/lib/providers/cash_vip_provider.dart`（或邻近）：`ensureVipSettled` / single-flight。
- `app/lib/providers/prediction_care_alert_provider.dart`：ensure 前 await VIP。
- `app/lib/ui/smart_prediction_screen.dart`：删除 L525 附近 build 内 catalog ensure。
- 可选：`app/lib/bootstrap/gateway_bootstrap_gate.dart` / `cold_start_background_sync.dart`：登录后 VIP 预热。
- 对照基线 `openspec/specs/v2.1.0.md` 与 `commercial-ucg-feature-unlock` 权益模型；无新 HTTP 路径（仍 `GET /cash/app/api/vip/status`）。
