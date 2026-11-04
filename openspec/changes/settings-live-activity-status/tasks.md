## 1. 解耦消息偏好与 LA 监听

- [x] 1.1 调整 `syncAppPushRegistration`：消息偏好 Off 时仍对已登录用户调用 `la.startIfEligible`；设备 push unregister 逻辑保持仅针对普通推送
- [x] 1.2 确认 `onAppResumeNotificationSync` / 其它路径不会在偏好 Off 时误停 LA；登出仍 `la.stop()`

## 2. 注册显态与手动重试 API

- [x] 2.1 扩展 `LiveActivityRegistrationService`（或并列状态源）：记录 listening、imminent/timing 的 `push_to_start` 成败、最近错误摘要；`_register` 成功/失败写入可观察状态（勿存完整 token）
- [x] 2.2 提供 force retry：先订阅再监听（或 stop 后重启），短超时等待两类 Push-to-Start 上报结果
- [x] 2.3 iOS 原生探测系统是否允许 Live Activities（如 `areActivitiesEnabled`）并经既有 MethodChannel 暴露；不支持平台返回明确 unsupported
- [x] 2.4 （建议）持久化 per-`attributesKind` 末次成功时间戳，杀进程后仍可显示曾成功上报

## 3. 设置中心 UI 与路由

- [x] 3.1 新增路由 `/settings/live-activity`（登录门禁同消息通知）与 `LiveActivitySettingsScreen`（玻璃面板风格对齐消息通知页）
- [x] 3.2 `settings_screen`：已登录且仅 iOS 展示「锁屏通知」入口
- [x] 3.3 子页：显态、开通/重试、系统未允许时跳转设置、下方失败信息；说明「开通指 token 已上报，展示仍依赖服务端推送」

## 4. 验收

- [x] 4.1 手工：消息偏好 Off + 已登录，仍可监听并在设置页看到重试/显态变化
- [x] 4.2 手工：模拟 register 失败或 token 超时，下方展示可读错误且无 token 明文
- [x] 4.3 Android/Web 设置中心无该入口；`dart analyze` 相关文件无新增问题
