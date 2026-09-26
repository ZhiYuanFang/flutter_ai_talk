## Why

开通中心智能分析（`care_alert_smart_remind`）卡在喂养资格未达标时仍展示支付/邀请等开通按钮，且资格态依赖其它页面预加载，易造成「未达标仍可开通/可进」的误解。产品要求：智能分析必须持续满足有效喂养门槛才能开通与使用；未达标时仅提示，不展示开通按钮行。

## What Changes

- 开通中心进入时 **必须** 自行 `ensureLoaded` care-alert eligibility（`GET /cash/app/api/care-alert/eligibility`）。
- 当 care 卡喂养未达标（`qualified != true`）时：
  - 卡片底部展示未达标提示（可用进度文案或简明提示）；
  - **不得** 展示支付 / 邀请码 / 免费体验开通按钮行；
  - 整卡点击以 **Toast** 提示未达标（不进详情、不去喂养确认框）。
- **BREAKING（产品语义）**：已商业开通或 VIP 覆盖后，若喂养资格回落未达标，开通中心同样不得进详情，底部改为未达标提示并 Toast；智能分析使用路径须持续依赖喂养达标（与详情/工作台既有资格闸对齐并补齐开通中心缺口）。
- 成长轨迹卡行为不变（不受喂养资格约束）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `feature-unlock-hub`: care 卡未达标隐藏 CTA、底部提示、点击 Toast；开通中心自拉 eligibility；已开通亦须喂养达标才可进详情。
- `feature-free-trial`: care 免费体验 / soft access 与开通中心 CTA 一致，未达标不得展示或进入。
- `feeding-eligibility-progress-copy`: 开通中心 care 未达标底部提示复用或对齐进度数字语义（不以 `message` 为权威）。

## Impact

- 代码：`feature_unlock_hub_screen.dart`（主）；必要时对齐 `feeding_analysis_screen` / `ai_analysis_screen` 的持续资格闸（若有绕过进详情路径）。
- API：复用既有 `care-alert/eligibility`，无新契约。
- 不在范围：成长轨迹喂养闸、AI Hub「去喂养」确认框形态（开通中心用 Toast）、服务端有效日计算规则。
