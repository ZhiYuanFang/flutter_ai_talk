## 1. 开通态相位

- [x] 1.1 增加 `predictEntitlementSettlePhase`（或等价 provider）：已绑定下 VIP 非 AsyncData 或 catalog 未 ready → syncing，否则 ready；失败结案算 ready
- [x] 1.2 文档化/复用 `ensurePredictDisplayEntitled`：await VIP + 确保 catalog 后再算 entitled

## 2. 弹窗闸

- [x] 2.1 改 `_PredictAlgoReadyHost` / `maybeShowPredictAlgoReadyOnboarding`：禁止首帧同步 `!entitled` 武装；await settle 后再判
- [x] 2.2 syncing 或 settle 后 entitled（含 VIP）→ 不弹、不 mark；仅 ready∧未 entitle∧亲和就绪∧未提醒才弹

## 3. 能力卡

- [x] 3.1 `PredictCapabilityStatusCard`：syncing 显示「正在同步能力中」；ready 后恢复档位文案优先级

## 4. Debug define

- [x] 4.1 `Env.clearPredictAlgoRemind` ← `CLEAR_PREDICT_ALGO_REMIND` default false
- [x] 4.2 启动早期：`kDebugMode && clearPredictAlgoRemind` → clear RemindStore + AppDebugLog；README 可补一行示例

## 5. 验收

- [ ] 5.1 手工：VIP 冷启动能力卡先「同步中」再 VIP 文案；不弹算法就绪窗、不误 mark
- [ ] 5.2 手工：非 VIP 非开通，settle 后才可能弹窗
- [ ] 5.3 手工：`flutter run --dart-define=CLEAR_PREDICT_ALGO_REMIND=true` 可再弹；不传 define 的 release 路径无清除
