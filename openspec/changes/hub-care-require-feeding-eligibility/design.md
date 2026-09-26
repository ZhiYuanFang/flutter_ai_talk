## Context

开通中心 care 卡当前：`showUnlockCtas = !unlocked`（支付/邀请不看喂养资格）；仅「免费体验」与 `canEnter` 看 `careAlertEligibilityStateProvider.isQualified`。Hub `initState` 不拉 care eligibility，依赖其它页预热。已开通但资格回落时卡面显示「已开通」且不可点，无未达标反馈。

产品拍板：未达标底部提示 + 隐藏全部开通按钮行；点击 Toast；Hub 自拉 eligibility；**已开通也必须持续喂养达标才能用**。

## Goals / Non-Goals

**Goals:**

- Hub 打开时 ensure care-alert eligibility。
- care 未达标：无支付/邀请/试用 CTA；底部未达标提示；整卡 tap → Toast。
- care 进详情（含已开通/VIP/试用）一律要求 `qualified == true`。
- 成长轨迹不变。

**Non-Goals:**

- 不改服务端有效日算法。
- 开通中心未达标不用「去喂养」确认框（Toast only）。
- 不改 AI 分析 Hub 未达标弹窗去喂养的既有形态（除非发现与「持续达标才能用」冲突的绕过，再对齐挡详情）。

## Decisions

### 1. 资格权威：后端 `qualified`

继续以 `GET /cash/app/api/care-alert/eligibility` 的 `qualified` 为准；底部提示优先复用 `FeedingEligibilityProgressText`（有 data 时），否则短文案「未达到有效喂养门槛」类。

### 2. CTA 与状态行统一受 `careEligOk` 约束

```
careEligOk = featureId != care || isQualified

showUnlockCtas = !unlocked && careEligOk
showUnqualifiedHint = !careEligOk   // 含已开通回落
canEnterDetail = commercialCanAccess && careEligOk
```

未达标时：不显示「已开通」剩余天数行，改显示未达标提示。

### 3. 整卡点击

- `canEnterDetail` → push 详情。
- `!careEligOk` → Toast（文案明确未达标；有进度时可带「还需 Y 天」简述）。
- 未开通但已达标 → 保持现状（非整卡进详情，靠 CTA）。

### 4. Hub 生命周期拉资格

在 `FeatureUnlockHubScreen.initState`（或与 catalog 同级的 post-frame）`unawaited(careAlertEligibility.ensureLoaded())`；下拉刷新一并 force/ensure。遵守既有 single-flight。

### 5. 「持续才能用」边界

开通中心与从开通中心进详情必须挡。喂养工作台已有 `isQualified` 闸则核对保留。不在本 change 强制改 AI Hub 去喂养确认框 UX。

## Risks / Trade-offs

- **[Risk] eligibility 加载中误显 CTA** → 未 ready 且非 qualified 时按未达标处理（藏 CTA）；loading 可用「正在校验…」底部文案。
- **[Risk] VIP 用户资格回落无法用分析** → 产品明确要求；Toast 说明需继续有效喂养。
- **[Trade-off] Toast vs 去喂养** → 产品选 Toast，减少跳转打断；用户需自行去喂养页。

## Migration Plan

纯客户端；回滚还原 Hub CTA/`canEnter`/init ensure 即可。

## Open Questions

- （无）Toast 文案实现时可定为：「需累计有效喂养日后方可使用智能分析」或带 remainingDays。
