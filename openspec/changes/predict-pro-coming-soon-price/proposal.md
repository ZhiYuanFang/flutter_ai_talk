## Why

Pro 两档墙卡外脚在未开通时仅显示「敬请期待」，用户看不到定价锚点；卡内已有「愿意付费开通」意愿文案，却缺具体金额。需要在不恢复支付 CTA 的前提下，把 catalog 月价以小字挂在「敬请期待」后面，帮助用户建立价格预期。

## What Changes

- Pro 档卡外脚为「敬请期待」时：在主文案**同行后面**追加小字价格，形态为 `¥{金额}/月`。
- 金额 **必须** 来自 catalog `predict_capability_pro` 的 `defaultProduct.priceFen`（分→元）；**不得**本地编造价格。
- 「/月」为产品**写死**月付文案，**不得**按 `durationDays` 动态换周期。
- catalog 无可用价（无 product / `priceFen<=0`）时：**隐藏**价格小字，只保留「敬请期待」。
- 脚仍为浅灰底黑字状态标签，**不可点**，**不得**变成支付/试用 CTA。
- 「正在使用」脚不加价；基础版脚不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-capability-tier-wall`：Pro「敬请期待」脚可同行展示 catalog 月价小字；无价隐藏；仍非支付 CTA。

## Impact

- Flutter：`predict_capability_tier_wall.dart`（`_FooterStatusLabel`）、可选薄封装读 `FeatureCatalogItem.defaultProduct`。
- 数据：复用既有 `featureCatalogStateProvider` / `predict_capability_pro` products；无新 API。
- 无 Android 原生；Release N/A。
- 叠在 `predict-pro-idea-wall` 之上，不改想法区 / Sheet。
