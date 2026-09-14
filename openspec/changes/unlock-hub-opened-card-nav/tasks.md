## 1. 已开通卡导航

- [x] 1.1 `_FeatureUnlockCard`：在有效开通且 featureId 为 care-alert / growth 时解析详情路由；其它情况无整卡 onTap
- [x] 1.2 用 InkWell（或等价）包裹卡片内容，`push` 到 `/prediction/ai-analysis/feeding` 或 `.../growth`；不添加箭头/查看文案

## 2. 验收

- [ ] 2.1 手工：已开通智能分析卡点进 feeding；已开通成长轨迹卡点进 growth
- [ ] 2.2 手工：未开通行整卡不跳详情，CTA 仍可用；无箭头 UI
