## Why

`predict-capability-client` 已落地双轨与算法就绪弹窗，但开通态（VIP / catalog）在 **Async 未 settle** 时被当成「未开通」：弹窗误弹并 mark 已提醒；中间能力卡也会短暂写成「固定间隔/待开通」。冷启动预期是先出预测页、静默拉态、就地更新内容——副作用闸必须 await，能力卡在同步中需明确占位。

## What Changes

- 引入预测开通态 **syncing / ready** 相位：VIP 未 AsyncData 或本机 catalog 未 ready 时为 syncing；不得把 syncing 当作未开通。
- 算法就绪弹窗：**await** VIP settle + catalog ensure 后再判 entitled；VIP/basic/pro 已覆盖则不弹、不 mark；仅 ready 且未 entitle 才弹。
- 中间预测能力卡在 syncing 时展示「正在同步能力中」；ready 后再按既有档位文案。
- 事件列表展示轨本轮保持策略 A：syncing 期间可继续 fail-closed 种子，不因 syncing 整页重挂。
- Debug：`--dart-define=CLEAR_PREDICT_ALGO_REMIND=true` 冷启动清已提醒缓存；默认 false，正式打包不传则无影响；建议仅 `kDebugMode` 生效。

## Capabilities

### New Capabilities

- `predict-entitlement-settle`：开通态 syncing/ready 合成、副作用 await 约定、能力卡同步中文案、debug 清提醒 define。

### Modified Capabilities

- `predict-capability-onboarding`：弹窗前必须 settle；syncing 不弹不 mark。
- `predict-capability-status-card`：syncing 展示「正在同步能力中」。

## Impact

- **依赖**：进行中的 `predict-capability-client`（双轨、弹窗、能力卡、RemindStore）。
- **代码**：`feature_unlock_provider` / `vipStatusProvider` 结算相位；`_PredictAlgoReadyHost` / `maybeShow…`；`PredictCapabilityStatusCard`；`Env` + 启动清缓存；可选 README dart-define 一行。
- **基线**：对照 `openspec/specs/v2.2.1.md` 与 change `predict-capability-client` delta。
