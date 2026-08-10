## Context

预测页 `_CareAlertPanel` 在 `state.failed && !state.loading` 时展示「接口异常」+ 刷新。详情页已有非 VIP「开通 VIP」→ `/vip/purchase`（`care-alert-vip-purchase`）。本变更只改**列表卡失败态**分流，复用同一 VIP 状态与购买路由。

## Goals / Non-Goals

**Goals:**

- 非 VIP（含 status 未知）失败态：文案「开通会员查看每日提醒」，点击进购买页。
- VIP 失败态：保留「接口异常」+ 刷新。
- 从购买页返回后刷新 status；若已是 VIP 则 force 重拉 care-alert daily。

**Non-Goals:**

- 不改变空态「宝宝成长得真棒！」与陪伴跳转。
- 不改变成功跑马灯 / 详情底栏 CTA 文案（详情仍可「开通 VIP」）。
- 不新增 VIP HTTP；不改 daily API 契约。
- 不把「门控未放行 / !ready」伪装成失败开通入口。

## Decisions

1. **VIP 判定与详情对齐**  
   `vipStatusProvider`：`isVip == true` 才走异常+刷新；`null` / 失败 / `!isVip` → 开通文案。  
   理由：与详情 CTA「失败当非 VIP」一致，避免卡死无入口。

2. **开通入口挂在失败分支，不挂 loading / !ready**  
   仅 `failed && !loading`。  
   理由：避免门控未放行时误导开通。

3. **回流重拉条件**  
   `push('/vip/purchase')` 返回后 `vipStatusProvider.refresh()`；仅当 `isVip` 为真才 `ensureLoaded(force: true)`。未开通返回不重拉，保持失败开通文案。

4. **Web**  
   与详情相同：Toast「请使用手机 App 开通 VIP」，不 push 购买页。

5. **刷新按钮**  
   非 VIP 失败态去掉刷新（整行点开通）；VIP 保留 `onRefresh`。

## Risks / Trade-offs

- [后端对非 VIP 故意失败当付费墙] → 产品接受；VIP 仍可见真异常。  
- [status 慢导致 VIP 短暂看到开通文案] → 可接受；status 到达后重建为异常+刷新。  
- [开通成功但 daily 仍失败] → 重拉后仍失败则走 VIP 异常+刷新，可再试。

## Migration Plan

纯客户端 UI；无数据迁移。回滚即恢复失败态「接口异常」+ 刷新。

## Open Questions

- （无；文案与 B 方案、回流重拉已由产品确认）
