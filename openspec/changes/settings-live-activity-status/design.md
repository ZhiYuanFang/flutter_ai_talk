## Context

`predict-ios-live-activity` 已实现 ActivityKit Push-to-Start、两类 Attributes，以及经 `LiveActivityRegistrationService` 上报 `POST /app/api/push/live-activity/register`。自动触发依赖 `appPushBootstrapProvider` / `syncAppPushRegistration`（登录后进壳、resume 通知同步、token 刷新等）。当前实现把 LA `startIfEligible` 挂在「消息通知」应用偏好之后：偏好关则 `la.stop()`，与产品「锁屏不与消息通知共用一把偏好」冲突。线上无系统日志时，无法向用户/客服展示注册阶段与失败原因。

## Goals / Non-Goals

**Goals:**

- iOS 设置中心「锁屏通知」入口 + 子页：注册显态、手动重试、下方失败信息（辅助无 log 排障）。
- 消息通知偏好与 LA 监听/register **解耦**；不改变自动 register 的触发集合（不新增冷启动/版本号渠道）。
- 将 `_register` 成败与阶段状态提升为可观察模型，供设置页绑定；失败文案可展示（勿展示完整 token）。

**Non-Goals:**

- 新增「锁屏通知 Off」持久化总开关。
- 重定义 token→HTTP 的自动时机；不改 Go register 契约；不做服务端「是否已存 token」查询。
- Android / Web 锁屏入口；替代 APNs/Go 全链路排障。
- 本地 `Activity.request` 起 LA。

## Decisions

1. **显态 + 重试，不加第二把 Off 开关。**  
   「开通」= 用户手动强制再走 listen（允许重置 `_started`）并等待 push_to_start 上报结果；系统未允许 Live Activities 时引导 `openAppSettings`。  
   *备选：独立 SharedPreferences 开关 — 本变更不做，以免与「只加显态/重试」范围膨胀。*

2. **资格门闩：已登录即可听 LA；与消息偏好无关。**  
   `syncAppPushRegistration`：消息偏好 Off 时仍可 `la.startIfEligible`（仅跳过设备 push register）；偏好 Off 的 unregister 只针对设备推送。设置页重试直接调用 LA 服务的 retry API，不要求消息偏好 On。

3. **状态模型（进程内为主，可选末次成功时间落盘）。**  
   Provider/服务暴露：系统版本是否支持 Push-to-Start、`areActivitiesEnabled`（原生探测）、是否已开始监听、imminent/timing 各自最近一次 `push_to_start` 成功与否、最近错误阶段与人话/可复制摘要（HTTP 业务 message、超时未收到系统 token 等）。  
   「已开通」定义：iOS ≥ 17.2 且系统允许，且 **imminent 与 timing** 的 `push_to_start` 均至少成功上报一次（本会话或持久化末次成功）。

4. **UI 对标消息通知页。**  
   `SettingsGlassPanel` + 说明文案；主操作「开通/重试」；系统未允许时「打开系统设置」；错误区在列表下方。入口：`settings_screen` 在「消息通知」旁，`!kIsWeb && Platform.isIOS && loggedIn`；路由 `/settings/live-activity`，登录门禁同消息通知。

5. **手动重试实现要点。**  
   先确保 Dart 已 subscribe `tokenStream`，再 `startListening`（或 force restart：stop → clear started → start），短超时（建议约 8–10s）等待两类 push_to_start 成功；超时或 HTTP 失败写入 `lastError` 供 UI。不新增自动触发点。

6. **排障边界写进文案/设计预期。**  
   页只保证客户端注册链可判；服务端开关/限流/APNs 投递导致「注册绿但锁屏不亮」不在本页结案范围。

## Risks / Trade-offs

- [系统从不吐 token] → 重试超时展示「未收到系统 token」；引导检查系统 Live Activities / 版本。  
- [首包在 subscribe 前丢失] → 重试路径强制 stop/start + 先听后启，降低偶发。  
- [用户以为绿=锁屏一定有] → 说明区写清「开通指 token 已上报；展示仍依赖服务端推送」。  
- [消息偏好解耦后关通知仍可能有锁屏] → 产品接受；与「不共用偏好」一致。

## Migration Plan

1. 随 App 发版；已登录用户进设置即可见入口，无需重新登录。  
2. 回滚：隐藏入口并恢复「偏好 Off 时 stop LA」即可（不推荐长期保留耦合）。

## Open Questions

- 末次 `push_to_start` 成功是否跨进程持久化：建议 **持久化 per attributesKind 成功时间戳**（无 token 明文），避免杀进程后显态全部变「未上报」造成误判；实现阶段可默认采用。
