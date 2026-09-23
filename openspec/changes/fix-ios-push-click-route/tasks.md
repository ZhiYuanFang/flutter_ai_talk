## 1. iOS 原生投递加固

- [x] 1.1 在 `SceneDelegate`（或 willConnect 等价路径）读取 `connectionOptions.notificationResponse`，提取 userInfo 并写入与 AppDelegate 相同的 pending 点击暂存
- [x] 1.2 整理 AppDelegate：`didReceive` / launchOptions / Scene 共用投递入口；优先抽出根级字符串 `bizType`；channel 未就绪时保留 pending
- [x] 1.3 为 `didReceive` / Scene 冷启入口增加 os_log/NSLog 打点（进/出与是否含 bizType），便于区分「回调未进」
- [x] 1.4 MethodChannel：保证 `getInitialNotificationTap`（或补拉 API）在 Dart 绑定后仍能取到 pending；热点击 `onNotificationTap` 优先传可解析载荷（字符串 bizType 或含 bizType 的 map）

## 2. Flutter 收件与失败 Toast

- [x] 2.1 更新 `UcgPushNative.bindNotificationTaps`：绑定 handler 后拉取 initial/pending；兼容字符串与 map；失败走统一上报
- [x] 2.2 在点击投递路径增加失败 Toast（`showAppToast` / `apiToastProvider`，error tone）：channel/getInitial 异常、已确认点击但无 `bizType`；**Release 也弹**；普通无点击启动不弹；成功不弹
- [x] 2.3 失败与成功入箱均打 `AppDebugLog.ucgPush`（禁止裸 print）；必要时对 Toast 文案做短时去重避免刷屏

## 3. 冷启消息 Tab + 热启点击（跟进）

- [x] 3.1 `UcgShell` 使用稳定 `GlobalKey`，资格锁 Overlay 切换时不重置 Tab
- [x] 3.2 消息 Tab 请求在资格未过时不 clear；合格后再 clear；资格上升沿再消费
- [x] 3.3 独立 `UcgNotificationCenterProxy` + 前台/Scene 夺回 delegate；pending 热投递 + ack；resume 补拉

## 4. 验收

- [ ] 4.1 真机冷启：UCG 通知 → 进消息列表（非停广场）
- [ ] 4.2 真机热启：任意页点 UCG/预测通知 → 按 bizType 切页
- [ ] 4.3 Release：投递/解析失败可见 Toast；Xcode 可见 `[ucg_push] proxy didReceive`
