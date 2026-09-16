## Why

商业开通模型混杂「宝宝维 / 用户维」「永久 / 期限」「预测槽位」「邀请同宝宝防刷」「假试用文案」，用户难理解、维护成本高。需要统一为**面向用户的期限开通 + 每功能一次真实免费体验**，并修正喂养分析入口误触与设置中心开通入口体验。

## What Changes

- **统一权益主体**：`care_alert_smart_remind` / `growth_trajectory_predict` 全部按 **用户（wx_id）** 开通与鉴权；不再按宝宝（device）写权益。
- **统一期限**：**BREAKING** — 支付开通一律 **30 天**；邀请码开通一律 **7 天**；删除广告开通路径；care 永久支付 SKU 改为 30 天（无存量付费用户，不做迁移）。
- **免费体验**：每账号每功能一次；catalog 返回 `trialAvailable`；开通页最右侧「免费体验」；**soft access** 可进详情并多次生成；**仅第一次分析/预测成功**后 claim，授予 **24h** 用户权益；VIP / 已开通不展示；care 仍须喂养达标。
- **日额度对齐**：**BREAKING** — care 智能分析由「宝宝日缓存一次」改为与成长轨迹一致：**用户每日最多 5 次、每次刷新**；进详情自动加载该用户该宝宝最新缓存（不扣次）。
- **结果隔离**：**BREAKING** — care / growth 最新结果按 **`(wx_id, device_no)`** 存储与读取，用户间完全隔离。
- **删除预测槽位**：**BREAKING** — 删除 `prediction_unlock` 开通能力及双端槽位门闸/相关死代码；预测事项不再做数量限制。
- **邀请码简化**：**BREAKING** — 去掉同宝宝受限与 `InviteOncePerDevice`；保留不可自用、人×码×功能不重复；**人×功能**邀请成功一次后不可再邀；catalog 返回 `inviteAvailable`，客户端不展示邀请开通按钮。
- **AI Hub / 详情 UX**：
  - 喂养分析详情：「AI智能分析」及说明文案移到正文下方横向居中。
  - 未喂养达标点喂养分析卡：弹窗提示，确认后再跳喂养页（防误触）。
  - 合格未开通点卡/成长未开通：功能介绍弹窗（无邀请输入框）；主按钮展示支付金额并直接支付；「其它方式开通」进入现有 `/features/unlock`。
- **设置中心**：去掉宝宝头像下开通摘要文案；登录后在宝宝卡片下方增加「功能开通」卡片，点击进入开通中心。
- **跨仓**：兄弟仓 `go_ai_talk` 同步改 cash 权益 / 邀请 / catalog / care·growth access 与结果键；本仓改 Flutter UI 与契约消费。无 Android 原生改动则不强制 release APK。

## Capabilities

### New Capabilities

- `feature-free-trial`：免费体验资格、soft access、成功后 claim 24h、开通页「免费体验」按钮与确认弹窗、与 VIP/已开通/喂养达标的展示门闸。
- `user-scoped-feature-commerce`：用户维期限开通总则（支付 30d / 邀请 7d / 无广告）、catalog `trialAvailable`/`inviteAvailable`、邀请人×功能一次、care 用户日 5 次刷新、结果键 `(wx_id, device_no)`、删除预测槽位后的商业边界。

### Modified Capabilities

- `ai-analysis-page`：Hub 喂养卡未达标弹窗；未开通改为介绍+支付弹窗；详情分析 CTA 位置；成长未开通弹窗同构。
- `feature-unlock-hub`：去掉看广告 CTA；按 `inviteAvailable`/`trialAvailable` 展示邀请与免费体验；支付仍为 30 天语义。
- `settings-center`：宝宝卡下「功能开通」入口，移除头像下开通摘要。
- `prediction-event-lock`：删除按 `allowedCount` 锁预测事件的要求（全开、无槽位）。
- `prediction-toggle-slot-gate`：删除满额邀请开槽门闸。
- `growth-trajectory-predict`：结果按用户隔离；支持试用 soft access 与成功 claim。
- `feature-entitlement-client`：权益合成与 catalog 新字段；不再依赖 device 维 care 权益与预测槽位计数。
- `feature-grant-duration-catalog`：与统一 30d/7d/试用 24h 对齐（广告天数废弃）。

## Impact

- **Flutter**：`ai_analysis_screen` / `feeding_analysis_screen` / `growth_trajectory_screen` / `ai_analysis_unlock` / `feature_unlock_hub_screen` / `settings_screen` / `smart_prediction_screen`（删槽位）/ `feature_unlock_*` models·providers·dialogs。
- **Go（`go_ai_talk`）**：`feature_const` / `feature_activate` / `feature_invite` / `feature_catalog` / `feature_grant` / care·growth access 与 voice 结果存储键；种子 SKU；删 ad / prediction_unlock 履约路径。
- 对照基线 `openspec/specs/v2.1.0.md`；上述 modified 能力多存在于既有 change specs，本变更以 delta 覆盖行为。
- 不自动新建 `**/test/**`。
