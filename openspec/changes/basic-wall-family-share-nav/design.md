## Context

基础版能力墙（`PredictCapabilityTierWall`）在 `_onBasicFeatureTap` 中按 `PredictBasicFeatureDemoKind` 落地。当前 `familyShare` 与 `nextEstimate` 同属「仅关墙」；设置入口已有 `/settings/baby-share`（`BabyShareScreen`，AppBar「邀请家人」），未绑定时页内提示绑定。v2.2.2 明确禁止 `familyShare` 跳转，本变更需规格与代码一并改。

## Goals / Non-Goals

**Goals:**

- 点「家庭全员共享」行：先关墙，再 `push('/settings/baby-share')`。
- 时序与其它导航 kind 一致（`pop` 后 `Future.microtask`）。
- 规格将「家庭共享不跳转」改为「进邀请家人」。

**Non-Goals:**

- 不改邀请家人页、二维码载荷、绑定流程。
- 不改墙文案 / demo 插画。
- 不在墙内做「未绑定」前置拦截（交给目标页空态）。
- 不改 `nextEstimate` 及其它 kind。

## Decisions

1. **目标路由**：复用 `/settings/baby-share`，与设置「邀请家人」同源。  
   - 备选：新建演示页 → 拒绝（重复产品面）。

2. **未绑定策略**：仍 push，由 `BabyShareScreen` 展示「请先绑定宝宝后再出示共享码」。  
   - 备选：墙内 SnackBar 拦截 → 拒绝（多一套文案与状态读取）。

3. **登录**：路由已在需登录列表；能力墙通常在已登录预测页打开。未登录走现有 redirect，不在本变更加二次鉴权。

4. **实现点**：仅拆开 `familyShare` 与 `nextEstimate` 的 `case` 合并，`familyShare` 增加 `router.push('/settings/baby-share')`。

## Risks / Trade-offs

- [未绑定用户点入看到空态] → 接受；与设置入口一致。  
- [与 v2.2.2 Scenario「家庭共享不跳转」冲突] → 本 change MODIFIED delta；收版合并基线。  
- [dialog dispose 后 push 失败] → 沿用现有「先抓 GoRouter，再 microtask」模式。

## Migration Plan

- 纯客户端行为变更，无数据迁移。  
- 回滚：恢复 `familyShare` 与 `nextEstimate` 同 `break`，并还原规格。

## Open Questions

（无）
