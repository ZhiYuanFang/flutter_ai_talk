## 1. 墙内 Pro 付费

- [x] 1.1 在 `predict_capability_tier_wall` 将原 `openHub`/`push('/features/unlock')` 改为墙内：eligibility → 支付确认弹窗 → `featurePaymentService.purchase` → toast → catalog refresh（对齐原 Hub Pro 支付闸）
- [x] 1.2 确认试用路径仍墙内 `trial/start`；墙内 **不得** 出现邀请码 / invite-howto 入口
- [x] 1.3 Web：确认后不发起真付（与原 Hub `kIsWeb` 行为一致）

## 2. 退休开通中心与设置入口

- [x] 2.1 设置中心删除「功能开通」glass tile；**保留**「清除历史媒体缓存」
- [x] 2.2 移除或 redirect `/features/unlock`；删除/停用 `FeatureUnlockHubScreen` 产品入口；清理 `ai_analysis_unlock` 等死链
- [x] 2.3 评估 `/features/invite-howto`：若仅 Hub 引用则移除路由或改为不可达；确保 Pro 路径无邀请

## 3. 校验

- [x] 3.1 `dart analyze` 相关改动文件无新增 error
- [ ] 3.2 手测：设置无开通卡、有清媒体；3h 墙试用/立即开通墙内付费；无邀请；深链 unlock 不进 Hub
- [x] 3.3 Android 原生未改：**N/A** release APK / proguard
