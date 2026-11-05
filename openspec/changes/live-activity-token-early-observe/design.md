## Context

当前 `PredictLiveActivityBridge` 仅在 Dart 调用 `startListening` 后 `beginObserving`；只订 `Activity.activityUpdates`，不枚举 `Activity.activities`。App 前台时链路正常；App killed 时系统 Push-to-Start 仍可锁屏展示（依赖已上报的 `push_to_start`），但 per-activity `pushTokenUpdates` 常无人订阅，`tokenKind=activity` 不上报，对端 update/end 失败。Apple 文档称 Push-to-Start 起 LA 时可能短暂唤醒 App；本仓观察起点过晚且缺补扫，赶不上该窗口。MethodChannel 强持有已由 `live-activity-channel-retain` 修好；本 change 解「订阅时机 / 已有实例」问题。

## Goals / Non-Goals

**Goals:**

- 进程启动早期即订阅 Push-to-Start 与 per-activity token（A）。
- 每次观察启动时枚举已有 `Activity.activities` 并订 `pushTokenUpdates`（B）。
- channel / Dart 未就绪时内存 inbox 暂存，就绪后 flush 进既有 `_register`。
- HTTP 仍在 Dart；登录门闸不变；副作用 HTTP 成功身份去重。

**Non-Goals:**

- 原生直接 `POST live-activity/register`（复制 Bearer/`deviceKey`）。
- pending 落盘跨进程持久化（首版内存即可）。
- iOS 18 channel / broadcast 替代 per-activity token。
- 本地 `Activity.request`；改 Go API；Android；设置页新诊断字段（可选后续）。

## Decisions

1. **Early observe 挂在 `didFinishLaunching`（及引擎就绪幂等确保）。**  
   不依赖 Flutter 登录壳。`startListening` 改为「确保观察 + 声明 Dart 可收 + flush inbox」。  
   备选：仅 resume 补扫 → 修不了后台唤醒窗口。

2. **观察与上报门闸分离。**  
   原生始终可观察；Dart 仅在已登录时 POST。未登录事件可入队，登录后 flush。  
   备选：未登录不观察 → 后台唤醒仍丢 token。

3. **Inbox 对齐 `UcgPushTapInbox`，首版仅内存。**  
   按 `tokenKind + attributesKind + activityId + token` 去重；成功 `invokeMethod` 后出队。覆盖「同一次进程内原生先到、Dart 后就绪」。  
   备选：App Group 落盘 → 复杂度高，留到真机证明同进程 flush 不够时再加。

4. **B：`beginObserving` 时先扫 `Activity.activities`，再订 `activityUpdates`。**  
   为每条 activity 开 `pushTokenUpdates` Task；需注意与 updates 路径重复投递 → 靠 inbox 去重 + Dart 成功缓存。

5. **HTTP 留 Dart + 成功身份缓存。**  
   身份：`deviceKey + tokenKind + attributesKind + activityId? + token`；未变跳过 POST；登出清缓存。对齐 `UcgPushRegistrationService` 与 project.md 副作用 HTTP。

6. **禁止原生独立 HTTP。**  
   避免双管线鉴权；后台若 Dart 赶不上，靠 inbox + 用户打开后 B 补扫兜底（接受「从不打开则仍可能无 activity token」的 OS 限制）。

## Risks / Trade-offs

- [系统完全不唤醒且用户不打开] → 仍无 activity token；缓解：文档写明；长期可评估 channel/broadcast（非本 change）。
- [重复 Task 订阅叠加] → restart 可能多 Task；缓解：去重 + 成功缓存；实现时尽量幂等 `started` 门闩。
- [后台唤醒但 Dart 未登录/无网] → inbox 内存，进程再杀仍丢；缓解：首版可接受；必要时二期落盘。
- [未登录观察产生无用 token 流量] → 仅内存队列，无 HTTP；登出后勿用旧 Bearer flush。

## Migration Plan

1. 发版含 early observe + activities 种子 + inbox + Dart 幂等。
2. 真机：killed → 起 LA → 查是否唤醒后 register；再测打开 App 后补报。
3. 回滚：恢复「仅 Dart startListening 才观察」即可；服务端契约不变。

## Open Questions

- （已定）pending 首版内存；未登录仍观察、仅登录后 POST。
- 设置页是否展示 activity token 见过/成功计数：本 change 不做，联调不够再开 diagnose 增量。
