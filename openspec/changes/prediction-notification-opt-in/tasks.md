## 1. 偏好与系统授权探测

- [x] 1.1 新增应用层消息通知偏好持久化（默认 true）与读写 API / Riverpod
- [x] 1.2 实现系统通知授权只读探测（Android `Permission.notification`；iOS 补齐 status 查询若仅有 request）
- [x] 1.3 App resume 时刷新授权状态；偏好 On + 已授权 + 已登录时可触发 register 同步
- [x] 1.4 会话级「横条已关闭」内存状态（进程内有效）

## 2. 推送注册门闸

- [x] 2.1 `syncAppPushRegistration` / bootstrap：偏好 Off 时跳过 register
- [x] 2.2 偏好切 Off 时调用既有 `unregister`；切 On 且已授权时触发 register

## 3. 设置中心与子页

- [x] 3.1 路由 `/settings/notifications`（登录门闸）与设置中心入口瓷砖
- [x] 3.2 子页：通知范围说明文案 + 总开关 + 系统未授权时的 request / 打开系统设置

## 4. 预测页横条

- [x] 4.1 竖屏正文顶（「接下来3小时」之上）按条件展示引导横条与开启/关闭控件
- [x] 4.2 横屏不渲染该横条；偏好 Off 或已授权或本会话已关不渲染
- [x] 4.3 Web / 未登录不展示横条

## 5. 验收

- [ ] 5.1 手工：系统关通知 → 竖屏预测见横条；点关闭后本会话不再出现；杀进程再进可再出现
- [ ] 5.2 手工：横屏无横条；设置总开关 Off 后 unregister 且预测不再催；再 On 且授权后可 register
- [x] 5.3 未改 `app/android/**`、未新增原生 SDK；仅 iOS `AppDelegate` 增加 `notificationStatus` 只读查询；跳过 release APK
