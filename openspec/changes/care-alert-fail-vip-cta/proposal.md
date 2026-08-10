## Why

智能预测页「值得留意」日拉取失败时，当前一律展示「接口异常」+ 刷新；对非 VIP 用户缺少与详情页一致的开通引导。需要在失败态按 VIP 身份分流文案与动作，并把开通回流与重拉串起来。

## What Changes

- 预测页值得留意卡在 **日拉取失败且非 loading** 时：
  - **非 VIP**（含 VIP 状态未知/加载失败按非 VIP）：展示文案「开通会员查看每日提醒」，整行可点，进入 `/vip/purchase`；不再展示刷新按钮。
  - **已是 VIP**：保持「接口异常」+ 刷新重试。
- 从购买页返回后：刷新 VIP 状态；若此时已是会员，则 `ensureLoaded(force: true)` 重拉日缓存。
- Web：开通入口行为与详情页一致（Toast 引导手机 App，不进原生购买页）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-care-alert`：预测页失败态按 VIP 分流文案/动作；开通回流后若已是 VIP 则强制重拉日缓存。

## Impact

- UI：`smart_prediction_screen.dart` 中 `_CareAlertPanel` 失败分支与调用方回调。
- 依赖既有：`vipStatusProvider`、`/vip/purchase`（`care-alert-vip-purchase`）、`predictionCareAlertStateProvider.ensureLoaded`。
- 无新 HTTP 契约；不改 care-alert daily API。
