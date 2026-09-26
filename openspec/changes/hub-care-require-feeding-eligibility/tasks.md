## 1. 开通中心加载资格

- [x] 1.1 `FeatureUnlockHubScreen` 首次进入时 `ensureLoaded` care-alert eligibility
- [x] 1.2 下拉刷新时一并刷新 care-alert eligibility

## 2. Care 卡未达标 UI / 交互

- [x] 2.1 未达标时隐藏支付 / 邀请 / 免费体验整行 CTA（`showUnlockCtas` 叠加 `careEligOk`）
- [x] 2.2 未达标时底部展示提示（有 data 用进度文案，否则短文案/校验中）
- [x] 2.3 未达标整卡点击 Toast，不进详情（含已开通/VIP 回落）
- [x] 2.4 已开通且达标时仍显示「已开通」态并可进详情；成长轨迹逻辑不变

## 3. 验收

- [x] 3.1 对照 specs：未达标无 CTA + Toast；Hub 自拉资格；已开通回落不可进详情
- [x] 3.2 确认喂养工作台既有 `isQualified` 闸仍生效（持续达标才能用）
