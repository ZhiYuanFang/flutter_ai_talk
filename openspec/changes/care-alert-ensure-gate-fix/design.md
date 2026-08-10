## Context

「值得留意」ensure 仅在 `UcgHomeShell._ensureCareAlertOnPredictionVisible`：门闸 `predictionCareAlertFetchAllowedProvider`（登录 + deviceNo + range.ready + items 非空）失败则静默 return。冷启动首帧 range 常未就绪；仅靠 `predictionRangeHistoryProvider` 的 wasEmpty listen 补拉，存在漏触发窗口。`deviceNo` 变更会 `clear()` 留意状态但不自动再 ensure。UI 将 `!ready` 与 `loading` 一并显示「加载中…」。实机 log：range 已 `filter ok count=113`，却无任何 `[CareAlert]` / `care-alert/daily`。

## Goals / Non-Goals

**Goals:**

- fetchAllowed 变为 true 时稳定 ensure。
- 门闸/跳过可观测（`[CareAlert]`）。
- 消除假加载文案；未就绪可刷新。
- 保持「无真历史不打 care-alert HTTP」。

**Non-Goals:**

- 不改 Go daily 契约与超时。
- 不改 VIP 空态文案语义（复用 `care-alert-widget-tip-align`）。
- 不在 provider create 时自动 HTTP。

## Decisions

### D1：听 `fetchAllowed` 边沿，而非只听 range wasEmpty

在 `UcgHomeShell`（或等价预测可见宿主）`ref.listen(predictionCareAlertFetchAllowedProvider)`：当 `prev != true && next == true` 且当前为预测页 → `ensureLoaded`（可保留现有 range listen 作冗余，或收敛为仅听 fetchAllowed）。

备选：给 range listen 加 `fireImmediately` → 否决（仍不覆盖 deviceNo 晚到）。

### D2：门闸拒绝必须打日志

`_ensureCareAlertOnPredictionVisible`（及 `ensureLoaded` 内 session/no-dn 早退）调用 `AppDebugLog.careAlert`，摘要 loggedIn / dnLen / range.ready / range.loading / itemCount，**不**打完整 deviceNo。

### D3：deviceNo clear 后补拉

care notifier 在 deviceNo 变化 `clear()` 后，若 `fetchAllowed` 且预测页可见，由 shell listen（D1 边沿或显式）再 ensure；避免 notifier 直接 import shell。可选：clear 后 `invalidate(predictionCareAlertEnsureProvider)` 并由 shell 已有 listen 消费——优先 D1 边沿覆盖「dn 从空到有 → fetchAllowed false→true」。

### D4：假加载 UI

`_CareAlertPanel`：

- `loading == true` →「加载中…」
- `failed || (!ready && !loading) || (ready && items.isEmpty)` → 空态族（VIP/非 VIP，含刷新）——与 tip-align 一致；「从未拉取」与失败/空列表同族，用户可点刷新 force ensure。

### D5：刷新路径

空态刷新已 `ensureLoaded(force: true)`；force **可**在无 range 时仍尝试（现实现如此）——本变更不收紧；门闸仅约束「自动可见 ensure」。

## Risks / Trade-offs

- [fetchAllowed 边沿抖动导致重复 ensure] → 既有 single-flight + 同日幂等。
- [未就绪走空态文案「真棒/开通」可能短暂误导] → 可接受；刷新可恢复；真加载仍显示加载中。
- [与 tip-align 未归档重叠] → 空态 UI 以 tip-align 为准，本 change 只修触发与假加载分支。

## Migration Plan

实现 → 冷启动看 `[CareAlert]` 与 `care-alert/daily` → 手工确认不再永久加载中。回滚 git revert。

## Open Questions

- （无）
