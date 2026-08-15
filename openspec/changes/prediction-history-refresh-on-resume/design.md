## Context

预测卡由 `predictionRangeHistory`（近 7 日）+ `homeHistory`（进行中计时）本地推演。`HomeScreen._onAppLifecycleResumed` 现只做 session / WS resume / 未读，不刷新历史；`predictionRangeEnsureProvider` 在 `ready && !_dirty` 时跳过。用户选定方案 **B**：resume 时同时刷喂养历史与预测 range。

副作用 HTTP 须遵守 `openspec/project.md`（single-flight、熔断、幂等）。

## Goals / Non-Goals

**Goals:**

- 已登录 App `resumed`：刷新 `homeHistory`（`bootstrap` / 等价远程刷新）并 `predictionRangeHistory.ensureLoaded(force: true)`。
- 停留在预测页回前台后，事件卡 / 进行中计时能反映最新服务端历史，无需先手动刷喂养页。
- 防护：复用既有 single-flight / range 熔断；短窗去重防连切。

**Non-Goals:**

- 不改预测算法本身；不新增预测 HTTP API。
- 不在 gave-up 态因本变更自动重连历史 WS。
- 不在未登录时拉历史。
- 不新建 `**/test/**`。

## Decisions

### D1：挂载点 = `HomeScreen._onAppLifecycleResumed`

与现有 session / WS / unread 同路径，保证主壳存活时 resume 一定触发。冷启动仍走既有 bootstrap，不重复发明。

顺序建议：

```
ensureFreshSession
→ feed/ucg WS onAppLifecycleResumed（既有）
→ ucg unread（既有）
→ 若已登录：并行
     homeHistory.bootstrap()
     predictionRangeHistory.ensureLoaded(force: true)
```

`bootstrap` 成功写 items 会 `scheduleInvalidation`；与显式 force 可能重叠 → range notifier single-flight 合并，可接受。

### D2：为何显式 force range，而不只靠 bootstrap 连锁

仅靠 `scheduleInvalidation` 依赖 bootstrap 成功写库；bootstrap 失败或空结果时预测仍可能不 dirty。显式 `force: true` 保证预测路径独立拉新。

### D3：短窗去重

内存记录上次 resume 历史刷新时刻；若距上次成功触发不足约 3–5s（实现取常量），跳过本轮喂养+range 刷新（session/WS/unread 不受影响）。满足「每段回前台拉一次」且防系统连发 resumed。

### D4：未登录 / 无 deviceNo

未登录：不调用。无 deviceNo：既有 range `ensureLoaded` 门控与 home bootstrap 行为保持，不另造假成功。

## Risks / Trade-offs

- [resume 双请求耗电/流量] → 短窗去重 + single-flight；可接受。
- [bootstrap 与 force range 竞态双拉] → range single-flight；可接受。
- [与 gave-up WS 规则冲突] → 本变更不碰 WS reconnect；仅 HTTP 历史。

## Migration Plan

- 纯客户端。回滚：移除 resume 内 bootstrap/force 即可。

## Open Questions

- （无）方案 B 已确认。
