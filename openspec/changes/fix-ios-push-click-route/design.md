## Context

基线 `push-click-home-route`（v2.1.2）已规定：点击只写入 inbox 的 `bizType`，回 `/home` 后由主壳分流。Android（HMS Intent `S.bizType` + china_push）可靠；iOS 仅靠 APNs `userInfo` → `AppDelegate.flutterTapArgs` → MethodChannel `com.fzy.pangbao/ucg_push`。工程已启用 UIScene + `FlutterImplicitEngineDelegate`，冷启时 `launchOptions[.remoteNotification]` 常为空，且 `SceneDelegate` 未读取 `connectionOptions.notificationResponse`。热路径依赖 `didReceive` → `invokeMethod("onNotificationTap")`；若 channel 未就绪，pending 写了却无人二次拉取则会永久丢失。现场：push-service `send_ok … bizType=ucg_alert`；在 UCG 页点预测通知无切页——说明业务分流未触发，投递层断裂。产品要求正式包也弹错误 Toast 以便真机排查。

## Goals / Non-Goals

**Goals:**

- iOS 冷启与热启点击均能把可识别 `bizType` 送入 `PushClickInbox`。
- Channel / 引擎时序下不丢 pending；优先传字符串 `bizType`（对齐 Android）。
- 投递或解析失败时，**Debug 与 Release** 均 Toast 错误文案；并保留 `AppDebugLog.ucgPush`。
- 原生入口可打点，区分「回调未进」与「进了但 Dart 解析失败」。

**Non-Goals:**

- 不改服务端 APNs/HMS payload 契约（当前根级 `bizType` 已正确）。
- 不改主壳分流表（登录态、`ucg_alert`→消息 Tab、资格锁层等）。
- 不引入 FCM / `flutter_local_notifications`。
- 成功点击不弹成功 Toast；不把 Toast 做成用户可读的产品引导文案体系。

## Decisions

1. **投递加固放在 iOS Native + `UcgPushNative.bindNotificationTaps`，分流逻辑不动**  
   - 理由：证据指向 inbox 之前；改主壳无法修复「seq 不涨」。  
   - 备选：仅加日志不做加固 → 否决（已知热路径会丢）。

2. **Scene 冷启：在 `SceneDelegate`（或等价 willConnect）消费 `notificationResponse`，写入与 AppDelegate 同一套 pending**  
   - 理由：UIScene 下标准冷启入口；仅靠 `launchOptions` 不足。  
   - 备选：去掉 Scene 回退旧 embedding → 成本过高。

3. **Dart 侧契约：优先接受 `bizType` 字符串（及现有 map）；`getInitial` 可在绑定后再次拉取或提供 `peekPending` 补拉**  
   - 理由：对齐 Android `getInitialPushClick` 返回 String；热点击 channel 瞬时失败时可补。  
   - 备选：只靠一次性 `getInitial` → 否决（已证明不够）。

4. **失败 Toast：走 `showAppToast` / `apiToastProvider`，Release 也弹**  
   - 理由：用户明确要求正式包可感知。  
   - 文案短前缀如 `推送点击:` + 原因（无 bizType / channel 异常 / getInitial 失败）。  
   - 备选：仅 kDebugMode → 否决（与本次需求冲突）。  
   - 注意：Toast 经 `normalizeUserFacingApiMessage` 时勿把诊断细节剥光；必要时对该路径使用不经过度归一化的展示，或专用短码。

5. **「完全无回调」靠原生 NSLog / os_log，不能只靠 Toast**  
   - 理由：Dart 未运行则无法 Toast。  
   - 实现：`didReceive` / Scene 通知入口进出各打一行。

6. **日志仍仅 `AppDebugLog.ucgPush`，禁止裸 print**  
   - 对照 project.md Debug 白名单；若需新 tag 则三联改（本变更优先复用 `ucgPush`）。

## Risks / Trade-offs

- [Release 误报打扰] → 仅在真实失败路径 Toast；成功静默；文案简短；后续可再加开关但本变更不做。  
- [无 bizType 的厂商噪声点击也 Toast] → 仅在「确认为通知点击回调且解析失败」时弹；普通冷启 `null` 不弹。  
- [Scene 与 AppDelegate 双写 pending 重复] → inbox 后写覆盖前写，同 bizType 可接受。  
- [Implicit Engine messenger 不一致] → channel 注册与 Dart MethodChannel 必须同一 engineBridge；设计评审时核对。

## Migration Plan

- 仅客户端发版；无需服务端迁移或数据迁移。  
- 回滚：回退 iOS/Dart 投递改动即可，分流代码未改。

## Open Questions

- Toast 是否需要「同一错误 N 秒内去重」以免连点刷屏（实现时可默认 2s 去重，非阻塞）。→ **已实现 2s 去重。**

## Follow-up（2026-09-23 真机反馈）

- 冷启能进 UCG 停广场：资格 `FeatureLockOverlay` 树变化重建 `UcgShell` → 已用 GlobalKey + 未合格不 clear 消息请求修复。
- 热启无反应：`didReceive` 易被挤掉 → 已用独立 `UcgNotificationCenterProxy`、becomeActive 夺回、pending+ack、resume 补拉。
