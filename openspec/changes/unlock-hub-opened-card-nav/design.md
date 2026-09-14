## Context

开通中心 `_FeatureUnlockCard` 已按 catalog 展示开通 CTA 或已开通状态，但整卡无导航。智能分析 / 成长轨迹的业务详情已存在于 AI 分析子路由：`/prediction/ai-analysis/feeding`、`/prediction/ai-analysis/growth`。有效开通判定沿用 `isFeatureEffectivelyUnlocked`。

## Goals / Non-Goals

**Goals:**

- 有效开通的智能分析、成长轨迹卡整卡可点，直达对应详情子页
- 未开通行不因本变更增加误跳；CTA 行为不变

**Non-Goals:**

- 不跳转到 AI 分析 Hub（`/prediction/ai-analysis`），只直达子页
- 不增加箭头、chevron、「查看」等可点暗示控件
- 不改预测槽位卡导航
- 不改详情页内部门闸 / 资格逻辑（子页仍自管）

## Decisions

1. **落点 A：直达子页**  
   - `care_alert_smart_remind` → `context.push('/prediction/ai-analysis/feeding')`  
   - `growth_trajectory_predict` → `context.push('/prediction/ai-analysis/growth')`  
   少一次 Hub 中转，符合「详情页」语义。备选 B（先 Hub）已否决。

2. **门闸：`isFeatureEffectivelyUnlocked`**  
   与卡上「已全部激活」同源（含 VIP），避免「看起来开通但点不进」或反之。

3. **仅这两类 featureId 挂 onTap**  
   用小表或 switch 映射路由；其它行 `onTap == null`。未开通时即使是这两类也不挂。

4. **手势：Material/InkWell 包住玻璃卡**  
   有 `onTap` 时包一层可点区域；无 CTA 的已开通态无按钮竞争。未开通行有 CTA 时不挂整卡 onTap，避免与 OutlinedButton 抢手势。

5. **无箭头**  
   产品明确不要额外暗示 UI；依赖整卡可点（系统 ripple 可保留作反馈）。

## Risks / Trade-offs

- [可发现性偏低（无箭头）] → 产品接受；ripple 提供反馈  
- [未合格用户 VIP 开通后进 feeding 仍见资格门] → 子页既有行为，本 change 不改  
- [与 brand-accent change 同改 hub 文件] → 合并时注意冲突，逻辑正交

## Migration Plan

纯客户端；回滚即去掉卡 onTap 映射。

## Open Questions

无。
