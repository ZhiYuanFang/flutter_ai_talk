## Context

首版在 `HomeScreen._onAppLifecycleResumed` 并行刷 `homeHistory` + prediction range。主壳默认着陆预测；喂养 KeepAlive 未必已 build → resume HTTP 可能不跑。`UcgHomeShell` 已有 resume（session + 历史 WS 自愈），且存在 `WS ready → return` 早退。值得留意资格/日列表与 UCG unread 仍挂喂养页或仅进 UCG 才校准，预测页停留时会陈旧。

## Goals / Non-Goals

**Goals:**

- 已登录 resume：主壳统一刷喂养历史、预测 range、值得留意 full ensure、UCG unread。
- 不依赖喂养页 mount；HTTP 与 WS heal 解耦。
- 短窗（约 4s）+ single-flight；未登录跳过。

**Non-Goals:**

- 不改预测算法 / 不新增预测 API。
- 不在 gave-up 因本变更自动重连历史 WS。
- 不做预测页广场入口球 / tip 球。
- 不新建 `**/test/**`。

## Decisions

### D1：挂载点 = `UcgHomeShell._onShellLifecycleResumed`（取代 HomeScreen）

主壳必活；与 WS 自愈同层。`HomeScreen` 删除 `_refreshPredictionHistoryOnResumeIfNeeded` 及 resume 内 `ucgUnreadSync`。

### D2：编排顺序

```
ensureFreshSession（已登录 + gateway 完成）
→ 并行启动（互不 early-return 对方）：
     A) 历史 WS 静默自愈（既有；ready 仅结束 A）
     B) HTTP bundle（短窗 + single-flight）：
          homeHistory.bootstrap()
          predictionRangeHistory.ensureLoaded(force: true)
          predictionCareAlertState.ensureLoaded(force: true)  // full：资格+日列表
          ucgUnreadSync()
```

**MUST NOT** 把 B 写在 `isHistoryWebSocketReady → return` 之后。

### D3：值得留意用 full ensure

`ensureLoaded(force: true)` 先资格再按需拉日列表，避免「后台刚合格仍停在进度文案」。

### D4：短窗去重

约 4s 内存短窗作用于整个 HTTP bundle（含 unread / care）；session / WS heal 不受该短窗跳过。

### D5：未登录 / 无 deviceNo

未登录：不跑 B。无 deviceNo：各 notifier 既有门控，不另造假成功。

## Risks / Trade-offs

- [resume 请求变多] → 短窗 + 各 provider single-flight；可接受。
- [与 HomeScreen 残留双触发] → 实现时必须删喂养页同类逻辑。
- [WS ready return 吞 HTTP] → D2 强制解耦。

## Migration Plan

- 纯客户端。回滚：恢复 HomeScreen 历史刷新并去掉 shell HTTP bundle。

## Open Questions

- 无（广场球另 change）。
