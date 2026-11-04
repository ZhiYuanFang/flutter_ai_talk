## Context

真机诊断 `ios=26.3 listening=1 ptsDeliver=4 immSeen=0 immOk=0 timSeen=0 timOk=0 err=partial_attributes`：ActivityKit 已吐 Push-to-Start，Bridge `deliver` 已计数，Dart 未 `ptsEventSeen`。Dart→Native 仍可用（messenger 按 channel **名** 留 handler），但 Native→Dart 依赖 `FlutterMethodChannel` 实例。当前 `AppDelegate` 用局部 `let laChannel` 赋给 `PredictLiveActivityBridge.channel`（`weak`），方法返回后 ARC 回收，`invokeMethod("onLiveActivityToken")` 走 `no_channel`。`ucgPushChannel` 则是 AppDelegate **强**属性，故普通推送出站正常。超时诊断把 `deliver>0 && !anySeen` 误标为 `partial_attributes`。

## Goals / Non-Goals

**Goals:**

- Native→Dart Live Activity token 投递在引擎存活期间可靠。
- `ptsDeliver` 只统计真正 invoke 到 Dart 的次数。
- 诊断将「原生已投、Dart 未收到」与「仅一类 attributes 成功」分开。

**Non-Goals:**

- 改 Go register 契约或自动 register 时机。
- 重写 ActivityKit 观察 Task 生命周期（本变更为 channel 持有与诊断）。
- 长队列持久化 token（可选短缓冲非必须）。

## Decisions

1. **强持有 channel，对齐 `ucgPushChannel`。**  
   `PredictLiveActivityBridge.channel` 改为 `static var`（非 weak）；`AppDelegate` 将 channel 赋给该静态并保留实例属性亦可。  
   *备选：仅 AppDelegate 强属性、Bridge 仍 weak — 只要有一处强引用即可；优先改 Bridge 为 strong，避免局部 `let` 再丢。*

2. **先 guard 再计数。**  
   `deliver`：`channel == nil` 只打 `no_channel` 日志、不增加 `pushToStartDeliverCount`；`invokeMethod` 之后再 ++。

3. **新错误类 `native_deliver_dart_miss`。**  
   超时路径：`pushToStartDeliverCount > 0` 且本轮 `!imminentSeen && !timingSeen` → 该类，人话：「原生已投递 token，但应用未收到（通道异常）」。  
   真·`partial_attributes` 仅在至少一类 `ptsEventSeen` 或一类 `registerOk` 时使用。

4. **不强制做 token 缓冲。**  
   强持有后主路径应通；引擎热重载窗口可后续再加。

## Risks / Trade-offs

- [静态强引用 channel 跨引擎重建] → 每次 `register` channel 时覆盖赋值（与现 ucg 路径一致）。  
- [修完后 ptsDeliver 可能变小] → 预期：只计真正送达。  

## Migration Plan

1. 随 App 发版；无数据迁移。  
2. 回滚：恢复 weak + 局部 let（不推荐）。

## Open Questions

- 无。
