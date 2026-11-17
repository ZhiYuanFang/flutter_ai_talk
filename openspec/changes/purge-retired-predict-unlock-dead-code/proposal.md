## Why

免费亲和单轨与开通中心/VIP/邀请退休后，客户端仍残留算法就绪提醒空转栈、零引用开通 stub、以及仅 `redirect → /home` 的退休路由表。这些代码不再承载产品行为，却持续增加阅读成本与误改风险；本变更一次性清掉，便于维护。

## What Changes

- **BREAKING（深链）**：删除仅兼容的 redirect 路由注册（`/companion`、`/prediction/alert`、`/prediction/ai-analysis*`、`/vip/purchase`、`/features/unlock`、`/features/invite-howto`）。旧链不再静默进主页；未匹配路径走既有 `errorBuilder`（宜提供回主页出口）。**保留**仍有业务副作用的 `/pangbao`。
- 删除算法就绪空转：`CLEAR_PREDICT_ALGO_REMIND`、`PredictAlgoReadyRemindStore`、wipe/main 清缓存、`_PredictAlgoReadyHost`、`maybeShowPredictAlgoReadyOnboarding` 及仅服务它的 `silentAffinityReady` / `rootAffinityReadyWithoutSeed`。
- 删除孤儿开通面：`invite_code_dialog.dart`、`ai_quota_remaining_hint.dart`、无站外引用的 entitlement helper（如 `isPredictDisplayEntitled`、`shouldShowFreeTrialCta` 等）、未上报的 `unlockHubShow` / `inviteHowtoShow` 用量事件常量。
- 邀请 howto 页类删除；**抽出** `resolveInviteGroupQrUrl` 供小智购买说明页继续使用。
- 试用成功文案去掉「开通中心」表述；保留 `showPredictBasicTrialSuccessDialog` 与 settle / Warmup 路径。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `feature-unlock-hub`：深链从「MUST redirect `/home`」改为「不得再注册该路由；不得渲染 Hub」；未匹配路径不得假装仍有开通中心。
- `predict-entitlement-settle`：REMOVED `CLEAR_PREDICT_ALGO_REMIND` / 算法就绪提醒缓存相关 Requirement；settle 相位本身保留。
- `predict-capability-onboarding`：REMOVED 算法就绪弹窗 / reminded 持久化相关 Requirement；试用成功玻璃确认保留但文案不得再指向开通中心。
- `feature-free-trial`：试用成功提示不得再写「可在开通中心查看到期时间」。

## Impact

- 代码：`app_router.dart`、`env.dart`、`main.dart`、`wipe_account_local_state.dart`、`predict_algo_ready_remind_store.dart`、`predict_capability_onboarding.dart`、`smart_prediction_screen.dart`、`smart_prediction_rows.dart`、`feature_unlock_provider.dart`、`client_usage_events.dart`、`feature_unlock/*`、`ai_quota_remaining_hint.dart`、`xiaozhi_speaker_buy_howto_screen.dart`；相关 README / logcat 若仍列 CLEAR define 则同步删。
- 行为：正常预测/墙内付费/试用/settle **不变**；仅旧退休深链与空转副作用消失。
- 依赖：无新包；纯减法。
- 对照基线：`openspec/specs/v2.2.1.md`；叠加 `retire-unlock-hub-pro-pay-in-wall`、`predict-capability-settle-gate`、`align-go-free-predict-retire` 已落地方向。
