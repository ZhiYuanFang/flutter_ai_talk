## Why

产品需临时收敛表面：广场与会员开通尚未到对外展示时机，同时预测页 chrome（底 tip、无内容/异常的「值得留意」、冷态假卡）噪音偏大。需要一版可翻转的闸门，先关掉入口与副作用，而不是删除 UCG/VIP 实现。

## What Changes

- **BREAKING（临时）**：主壳 PageView **不得**再提供 UCG 页；用户 **不得** 横滑或 `requestPage` 进入广场；`UcgShell` **不得**因主壳导航被挂载。
- **BREAKING（临时）**：历史编辑「同步广场」开关 **不得**展示（含已选媒体）；保存路径 **必须**按同步关闭处理，**不得** `createPost` / `updatePost` / `deletePost`；媒体仍可走本地缓存。
- **BREAKING**：智能预测页 **删除**底部 tip 横向跑马灯（及挂载）；桌面小组件 tip 推送 **不在本变更范围**（默认保留）。
- **BREAKING**：「值得留意」**仅当**日拉取成功且过滤后有条目时展示卡片；loading / 空列表 / 接口异常 / 非 VIP 开通文案 / 冷态健康假卡 **一律不展示**。
- **BREAKING（临时）**：VIP 购买页与开通 CTA **不可达**（含 `/vip/purchase` 深链）；详情页底部开通 CTA 保持关闭。
- Auth 冷态滑动引导大卡 **保留**，文案改为只引导喂养（去掉「左滑进广场」）。
- 实现以编译期/常量 feature flag 为准，便于下版翻回；不删 `app/lib/ucg/**` 与支付实现主体。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `ucg-home-entry`：主壳临时两页（喂养 | 预测）；禁止进入/挂载 UCG；返回与 `requestPage(ucg)` 行为收敛。
- `history-event-square-sync`：临时隐藏同步开关并强制关闭同步副作用（仍允许本地媒体缓存）。
- `home-history-edit-sheet`：保存行不再要求展示「同步广场」开关（与 square-sync 闸门一致）。
- `smart-prediction-page`：去掉底 tip 跑马灯；Auth 引导大卡改文案；留意卡可见性与本变更 `prediction-care-alert` 对齐。
- `prediction-care-alert`：仅有条目才展示；废除常驻卡 / 失败 VIP CTA / 冷态假卡展示要求（ensure 门闸可保留）。
- `vip-purchase-ux`：购买路由与 UI 开通入口暂时不可达。

## Impact

- **壳层**：`UcgHomeShell`、`HomePagerPage`、预测页滑动引导文案、Android 返回（喂养↔预测，无 UCG 分支）。
- **历史编辑**：`home_history_edit_sheet.dart`、`runHistoryEventMediaSideEffects` 调用约定。
- **预测 UI**：`smart_prediction_screen.dart`（`_BottomTipMarquee`、`_CareAlertPanel`、`_CareAlertDemoHealthyPanel`、Auth 大卡）。
- **VIP**：`app_router.dart` `/vip/purchase`、`prediction_care_alert_screen.dart`、预测页 `onOpenVip` 路径。
- **规格**：相对未归档 change（如 `llm-care-alert-daily`、`care-alert-fail-vip-cta`、`prediction-tip-bottom-marquee`、`prediction-demo-skeleton-and-recall-dialog`、`prediction-as-home-hub`）为临时覆写。
- **测试**：不新建 `**/test/**`；手工验收导航、编辑保存、留意显隐、购买深链。
