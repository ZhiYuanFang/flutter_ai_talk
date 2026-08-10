## Context

logcat 已复现：`range filter ok count=0` 且无 `GET .../filter`，同时随后 `/list?deviceNo=…` 有数据。根因是 `RemoteFeedRepository.tryLoadHistoryFilter` 在 `deviceNo` 空时 `return const []`，被 `fetchPredictionSevenDayHistory` / `ensureLoaded` 当成成功并 `ready=true`；之后 ensure 因 ready 跳过。Splash `unawaited(ensureWidgetReadyFromRef)` 可早于 ColdStart `deviceNo.refresh()`。

## Goals / Non-Goals

**Goals:**

- 无 deviceNo 不得把 range 标为成功 ready。
- ensure 前尽力 `refresh` deviceNo；仍无则失败语义（不 ready）。
- `ready && items.isEmpty && deviceNo 已有` 时 force 再拉（进页自愈）。
- 预测页区分 loading / 真空。

**Non-Goals:**

- 不改 filter/v2 服务端契约与 7 日窗算法。
- 不把 range 合并进 homeHistory 分页。
- 不新建测试文件。

## Decisions

1. **空 dn → `null`（失败）**  
   `tryLoadHistoryFilter` / `tryLoadHistoryPageV2`（及同类）在 dn 空时返回 `null`（或与「未登录跳过」区分的明确失败），**不得**返回成功 `[]`。  
   **备选**：仅在 ensure 层检查 dn——不够，其它调用方仍会踩坑。

2. **ensure 入口灌 dn**  
   已登录时 `ensureLoaded` 若 dn 空：`await deviceNoNotifier.refresh()`；仍空则不调用 fetch、不置 `ready=true`（可保持 loading=false、ready=false，记 debug 日志）。

3. **假空自愈**  
   `ensureLoaded`：若 `ready && items.isEmpty` 且 dn 非空且未 circuit，则视为需重拉（等价 force 或清 ready），避免进页空转。真·近 7 日无记录时再拉仍为空——可接受；可用短时「已对某 dn 空结果确认」标记避免热循环（可选：同 session 内空成功后跳过，直至 dirty/invalidation）。

4. **UI**  
   `!ready || loading` → 「正在加载中」（或等价）；`ready && rows.isEmpty` → 「暂无…」。

5. **Splash 时序（最小改）**  
   优先靠 1–3 自愈；若仍易抢跑，可将 `app.dart` 中已登录的 `unawaited(ensureWidgetReadyFromRef)` 改为在 ColdStart/`deviceNo.refresh` 之后，或去掉与 gate 重复的提前 ensure（gate 已会 ensure）。实现选改动面更小者。

## Risks / Trade-offs

- [真无记录时进页多一次 filter] → 可接受；或加「空结果已确认」标记。  
- [未绑定宝宝反复 ensure 失败] → 不标 ready，UI 加载/引导；不锁死空列表。  
- [v2 空 dn 也改 null] → 与 filter 一致，避免另一路径假成功。

## Migration Plan

- 纯客户端；热重载/重装即可。已锁死会话：进页自愈或杀进程后 ColdStart 顺序修复。

## Open Questions

- （无）产品已确认按竞态修复 + 空态分流。
