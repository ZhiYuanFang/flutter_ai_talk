## Why

AI 分析页「合格未开通」目前直跳开通中心，缺少邀请码兑换入口；正文所需的「x 天」必须来自服务端可配置的邀请授予天数，而不能误用付费 SKU 的 `products[].durationDays`。服务端虽已有 `feature_def.duration_days`（邀请/广告授予同源），但 **App catalog 未下发**，且运营无法分别改邀请与广告天数。

## What Changes

- **服务端（go_ai_talk）**：在 `feature_def` 增加 `invite_duration_days` / `ad_duration_days`；迁移自现有 `duration_days`；邀请/广告开通原子入口分别读取对应列；Admin 可改；`GET /cash/app/api/feature/catalog` 每项下发 `inviteDurationDays` / `adDurationDays`（0=永久）。
- **客户端**：解析上述字段；AI 分析页合格未开通点击先弹出共享邀请码玻璃框（标题「智能分析」、正文含邀请授予天数、左「获取邀请码」、右「开通」）；空码 → `/features/unlock`；有码 → redeem `care_alert_smart_remind` 后刷新 catalog 留在本页。
- 正文采用折中话术：恭喜获得试用资格，输入邀请码即可兑换 x 天智能分析使用额度。
- **非 BREAKING**：旧客户端忽略新字段；缺字段时客户端弱化天数文案，不得用付费 SKU 天数冒充。

## Capabilities

### New Capabilities

- `feature-grant-duration-catalog`：catalog 下发并消费邀请/广告授予天数（跨端契约）
- `ai-analysis-page`：AI 分析页合格未开通邀请码弹框门闸（与 `ai-analysis-care-alert-relocate` 同能力名；本 change 补充开通弹框增量）

### Modified Capabilities

- （无基线已合并能力需改；开通中心 hub 文案对齐不在本 change 必达范围）

## Impact

- **go_ai_talk**：`feature_def` DDL/迁移、`feature_activate`、Admin 更新、catalog 合成与 `api/v1` DTO、缓存失效键
- **flutter_ai_talk**：`FeatureCatalogItem` 模型、`ai_analysis_screen` 开通入口、复用 `showInviteCodeDialog`
- 开通中心广告/邀请弹窗可后续复用同一字段（本 change 以 AI 分析入口为必达；hub 文案对齐为可选跟进）
