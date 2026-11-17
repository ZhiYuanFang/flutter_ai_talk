## Context

父变更 `predict-capability-client` 用 `predictDisplayEntitledProvider`（`vipStatus.valueOrNull?.isVip` + catalog）驱动展示轨与弹窗 Host。VIP/`catalog` 首帧常为 loading/未 ready → `entitled=false` → Host 武装弹窗并 markReminded，VIP 用户被误伤。能力卡同步用同一 bool，syncing 时会闪「固定间隔/待开通」。

产品冷启动：先出预测页 → 静默拉 VIP/catalog → 就地更新内容；**不是**整页 remount。列表策略本轮采用 A：仅卡与弹窗严格 await；列表可短暂 fail-closed。

## Goals / Non-Goals

**Goals:**

- syncing ≠ 未开通；弹窗与能力卡尊重相位。
- 弹窗路径 await `ensureVipSettled` + `catalog.ensureLoaded` 后再判。
- 能力卡 syncing 文案「正在同步能力中」。
- Debug dart-define 清已提醒；默认不影响 release。

**Non-Goals:**

- 实现 Pro 服务端预测源。
- syncing 期间列表强制空白骨架（策略 B）。
- 改 Go 门禁。
- 新建 `**/test/**`。

## Decisions

### D1：相位合成 `predictEntitlementSettlePhase`

```
syncing  WHEN 已登录已绑定且
           (vipStatus 尚非 AsyncData
            OR catalog 对本 deviceNo 尚未 ready)
ready    OTHERWISE（含未登录/未绑定：无商业相位，按非 syncing 处理）
```

失败也算 ready：VIP fail-closed null、catalog failed 可带旧 items —— 避免永久卡在「同步中」。

### D2：弹窗闸只认 ready

`maybeShowPredictAlgoReadyOnboarding`（或 Host）MUST：

1. `silentAffinityReady` 否则 return  
2. `await ensureVipSettled` + `await catalog.ensureLoaded`  
3. 若此时 `isPredictDisplayEntitled` → return（不 mark）  
4. 再查 reminded / show / mark  

禁止用首帧同步 `!entitled` 武装；`_armed` 仅在 settle 完成后对「已处理本会话」置位，避免 VIP 迟到仍弹。

### D3：能力卡

| phase | 标题 |
|-------|------|
| syncing | 正在同步能力中 |
| ready | 沿用 pro→basic→VIP→待开通→固定间隔 |

点击进开通页：syncing 时 MAY 仍允许（或禁用至 ready）；默认 **仍可点** 进开通中心。

### D4：列表策略 A

`smartPredictionBundle` 的 `displayEntitled` 在 syncing 时继续 false（fail-closed 种子）可接受；VIP settle 后就地切亲和。不为此整页重建路由。

### D5：Debug define

- `Env.clearPredictAlgoRemind` = `CLEAR_PREDICT_ALGO_REMIND` default false  
- 启动早期：`kDebugMode && clearPredictAlgoRemind` → `PredictAlgoReadyRemindStore.clearAll()` + AppDebugLog  
- Release 无 define / default → 无行为  

### D6：与父变更关系

本变更是父变更的 settle 闸补丁；apply 时改同一套文件，不重复造双轨。

## Risks / Trade-offs

- [catalog 慢] → 能力卡久停「同步中」；列表仍可用种子。可接受。  
- [VIP 失败 null] → ready 且非 VIP，可能弹窗；与 fail-closed 一致。  
- [define 误进 CI release] → `kDebugMode` 门降低风险。

## Migration Plan

无数据迁移。已误 mark 的 VIP 用户可用 debug define 清缓存复测。

## Open Questions

无（列表策略 A、卡文案、define 名已在 explore 拍板）。
