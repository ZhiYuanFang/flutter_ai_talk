## 1. VIP settle API

- [x] 1.1 在 `cash_vip_provider.dart`（或邻近）实现共享 `ensureVipSettled`：未登录秒回；已 settled 非 force 秒回；single-flight；失败 fail-closed 非 VIP
- [x] 1.2 确认不在 `_runColdStart` / 启动遮罩路径 await VIP；登录后可选 kick 预热（`GatewayBootstrapGate` 或 `ColdStartBackgroundSync`，默认 kick 不挡 `_loggedInComplete`）

## 2. 接入门闸

- [x] 2.1 `PredictionCareAlertNotifier._ensureImpl`：在 `isFeatureEffectivelyUnlocked` / daily 分支前 `await ensureVipSettled()`，用 settle 结果算 `isVip`
- [x] 2.2 删除 `SmartPredictionScreen.build` 内 `featureCatalog.ensureLoaded()`（约 L525）；依赖壳层进预测 catalog ensure
- [x] 2.3 （可选）预测开关 `_requestForecastToggle` 入口 await VIP settle，减少瞬时误拦

## 3. 校验

- [x] 3.1 `openspec validate vip-settled-before-entitlement-gates --strict` 通过
- [ ] 3.2 手工：冷启 VIP + catalog 未单独开通值得留意 → settle 后应拉 daily / 不因 loading 永久「去开通」；预测页无 build 改 provider 断言；启动遮罩无明显因 VIP 变长
