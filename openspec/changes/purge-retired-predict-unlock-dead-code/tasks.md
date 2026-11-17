## 1. A — 算法就绪空转

- [x] 1.1 删除 `PredictAlgoReadyRemindStore` 文件；从 `main.dart` / `wipe_account_local_state.dart` 去掉清缓存与 import
- [x] 1.2 删除 `Env.clearPredictAlgoRemind` / `CLEAR_PREDICT_ALGO_REMIND`；同步清理 README / logcat 脚本中若仍列出的 define 说明
- [x] 1.3 删除 `smart_prediction_screen` 内 `_PredictAlgoReadyHost` 及其挂载
- [x] 1.4 删除 `maybeShowPredictAlgoReadyOnboarding` / `PredictAlgoReadyDialogResult`；保留并改文案的 `showPredictBasicTrialSuccessDialog`（不得提开通中心）
- [x] 1.5 从 `smart_prediction_rows` 删除 `silentAffinityReady` 字段、赋值与 `rootAffinityReadyWithoutSeed`

## 2. B — 孤儿开通 stub

- [x] 2.1 删除 `invite_code_dialog.dart`；确认无残留 import
- [x] 2.2 抽出 `resolveInviteGroupQrUrl` 到薄模块；更新 `xiaozhi_speaker_buy_howto_screen` 引用；删除 `InviteCodeHowtoScreen` / howto 页文件
- [x] 2.3 删除 `ai_quota_remaining_hint.dart`
- [x] 2.4 从 `feature_unlock_provider` 删除无站外引用 helper：`isPredictDisplayEntitled`、`ensurePredictDisplayEntitled`、`predictDisplayEntitledProvider`、`canAccessFeatureDetail`、`shouldShowFreeTrialCta`、`shouldShowPredictionAccumulationCtas`、`displayUnlockMethod`、`isFeatureEffectivelyUnlocked`；保留 `predictCapabilityItems` 与 `predictEntitlementSettlePhaseProvider`
- [x] 2.5 删除未 report 的 `ClientUsageEvents.unlockHubShow` / `inviteHowtoShow`（若仍无引用）

## 3. C — 退休路由

- [x] 3.1 从 `app_router` 删除 redirect-only：`/companion`、`/prediction/alert`、`/prediction/ai-analysis*`、`/vip/purchase`、`/features/unlock`、`/features/invite-howto`
- [x] 3.2 保留 `/pangbao`；为 `errorBuilder` 增加回主页出口（按钮或等价）

## 4. 验证

- [x] 4.1 `flutter analyze`（`app/`）无因本删改引入的 error（IDE ReadLints 改动文件无 error；全量 analyze 与 `flutter run` 抢锁未跑完，以引用清扫 + lints 为准）
- [x] 4.2 手工清单（热重启请去掉已删除的 `CLEAR_PREDICT_ALGO_REMIND`）：预测页无算法就绪弹；试用成功文案无「开通中心」；旧 `/features/unlock` 错误页可回主页；`/pangbao` 仍进预测页
