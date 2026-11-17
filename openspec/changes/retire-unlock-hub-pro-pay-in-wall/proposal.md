## Why

功能开通中心与设置「功能开通」卡仍承载已退休的 care/growth/VIP 叙事，且 Pro 支付要多跳一层。产品收敛为：从「接下来3小时」两档墙内直接付费开通 Pro；不再提供开通中心、不再提供邀请码开通；设置侧去掉开通入口。清除历史媒体缓存入口保留。

## What Changes

- **BREAKING（产品入口）**：移除设置中心「功能开通」卡；移除 `/features/unlock` 开通中心页（及路由注册）；深链进入该路径时 MUST 回退安全页（如 `/home`），不得再渲染 Hub。
- 「接下来3小时」两档墙 Pro 底栏「立即开通」：在墙内完成 eligibility 闸 + 价格确认 + `featurePaymentService.purchase`，**不得**再 `push` 开通中心。
- Pro 客户端 **不得**再提供邀请码兑换 / 「如何获取邀请码」作为开通路径（墙内与已删 Hub 均无入口）。
- 墙内试用（`trial/start`）保留；免费档说明与 `Icons.upgrade` / 整卡开墙行为以既有 `next-three-hours-tier-card-tap` 为准（本变更不回退）。
- **不改**：设置「清除历史媒体缓存」、切号不因此清媒体、小智音箱独立开通页、catalog / predict-pro eligibility 数据层。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `feature-unlock-hub`：开通中心不再作为用户可达产品面；相关「Hub 必须展示 Pro 壳」等要求改为退休/禁止入口。
- `predict-free-pro-chrome`：Pro「立即开通」改为墙内直付；禁止跳转 Hub；禁止邀请码开通 CTA。
- `settings-center`：登录后宝宝卡下方 **不得** 再展示「功能开通」卡；**必须** 保留「清除历史媒体缓存」。

## Impact

- UI：`settings_screen.dart`、`feature_unlock_hub_screen.dart`（删除或停用）、`app_router.dart`、`predict_capability_tier_wall.dart`、`predict_capability_tier.dart`（`openHub`→墙内付费）；清理仍指向 Hub 的死链（如 `ai_analysis_unlock.dart`）。
- 复用：`feature_pay_helpers` / `featurePaymentService` / eligibility Provider；邀请码对话框可保留给其它能力，但 Pro/墙路径不得调用。
- 无新原生 SDK；Android release N/A（除非误触 android/）。
- 兄弟仓 Go：邀请 API 可仍存在，本变更仅客户端不接 Pro 邀请入口。
