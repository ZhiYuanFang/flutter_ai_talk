## 1. 开通中心字色

- [x] 1.1 `feature_unlock_hub_screen.dart`：功能卡标题与介绍由 `onShell` 改为行 `accent`（介绍可降透）
- [x] 1.2 确认 CTA / 徽章 / 时效仍跟 accent；页级 AppBar / 空态不强制改色

## 2. 喂养工作台字色

- [x] 2.1 `feeding_analysis_screen.dart`：卡内标题、副文案、`_muted`、开通引导改跟 care-alert accent（浅底加深）
- [x] 2.2 `_FeedingBlurb` 正文改跟 accent（加深）；玻璃壳 / 列表结构不动

## 3. 成长工作台字色

- [x] 3.1 `growth_trajectory_screen.dart`：AppBar 标题、`_GrowthBlurb`、muted / thinking / 问题 prompt 改跟成长 accent（浅底加深）
- [x] 3.2 确认整页渐变壳、SSE / 开通 / 日限行为未改

## 4. 验收

- [ ] 4.1 手工：开通中心多行卡标题/介绍跟各自功能色；CTA 仍清晰
- [ ] 4.2 手工：喂养 / 成长工作台页内文案跟功能色，浅底可读；结构与 Hub 模拟样张无关
