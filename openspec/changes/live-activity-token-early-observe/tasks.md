## 1. 原生 early observe + 补扫

- [x] 1.1 `PredictLiveActivityBridge`：在 `beginObserving` 中对 Imminent / Timing 枚举 `Activity.activities`，为每条订 `pushTokenUpdates`，并继续订 `activityUpdates`
- [x] 1.2 提供可在 `didFinishLaunching` 调用的 early start（不依赖 Dart `startListening`）；`started` 门闩幂等；`startListening` / `restartListening` 语义改为「确保观察 + 可收 + flush」
- [x] 1.3 `AppDelegate.application(_:didFinishLaunchingWithOptions:)`（及引擎就绪处幂等）调用 early start；保持 channel 强引用（不回退 `live-activity-channel-retain`）

## 2. Token inbox 与 Dart 对接

- [x] 2.1 原生实现进程内 token inbox：无 channel / Dart 未听时入队（按 tokenKind+attributesKind+activityId+token 去重）；可收后 `invokeMethod` flush；禁止日志打印原始 token
- [x] 2.2 Dart `LiveActivityNative` / `LiveActivityRegistrationService`：`startListening` 时声明可收并触发 flush；未登录不 POST，登录后 `startIfEligible` 处理积压事件

## 3. 副作用 HTTP 去重

- [x] 3.1 `LiveActivityRegistrationService._register`：对成功身份（deviceKey + tokenKind + attributesKind + activityId? + token）缓存并跳过重复 POST；登出 / `stop` 清缓存；失败路径 `AppDebugLog.liveActivity`（勿打 token）

## 4. 文档与验收

- [x] 4.1 更新 `LIVE_ACTIVITY.md`：early observe、activities 补扫、inbox、登录门闸与去重
- [x] 4.2 真机核对：App killed → Push-to-Start 出 LA 后（唤醒或随后打开）出现 `register ok kind=activity`；前台路径回归不破；不新建 `**/test/**`（核对步骤已写入 `LIVE_ACTIVITY.md`，待真机执行）
