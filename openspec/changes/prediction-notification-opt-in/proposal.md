## Why

预测临近等离线提醒依赖系统通知权限与全局推送注册，但用户关闭授权后页面无引导，只能干等不到提醒。需要在预测页竖屏用轻量横条说明价值并引导开启；同时在设置中提供说明与总开关，让用户既能理解「通知包含什么」，也能主动关掉（unregister），避免只有「催开」没有「可关」。

## What Changes

- 预测页**竖屏**正文顶部（「接下来3小时」之上）：当已登录、应用层通知偏好未关、系统通知未授权、且本会话未关闭横条时，展示引导横条；文案说明开启后可在事件即将发生时收到服务通知，不必一直盯手机、也可减少忘记录。
- 横条可关闭：**仅本次会话**（内存）；杀进程后再进可再出现（在仍未授权且偏好未关时）。
- **横屏不出横条**。
- 设置中心新增「消息通知」入口（登录可见）→ 子页说明通知包含内容 + 总开关。
- 应用层偏好 **Off**：调用既有 `unregister`，且 bootstrap **不得**再自动 register；预测横条 **不得**再催开。
- 应用层偏好 **On**：在系统已授权（或用户经横条/子页完成授权）后走既有 `register`；系统未授权时子页引导 request / 打开系统设置。
- 不改 Go 推送协议；不新增厂商 SDK；不做「只关预测、保留广场」的分类开关（同一 token，总开关一并生效）。

## Capabilities

### New Capabilities

- `app-notification-preference`：应用层消息通知偏好、系统授权检测、设置子页说明与总开关、与全局 push register/unregister 门闸。

### Modified Capabilities

- `smart-prediction-page`：竖屏正文顶通知引导横条（会话可关；横屏不展示）。
- `settings-center`：设置中心增加消息通知入口（登录）。
- `app-global-push-registration`：register 路径 MUST 尊重应用层偏好 Off（不得在偏好关闭时仍自动注册）。

## Impact

- Flutter：预测页 UI；设置路由/子页；权限 status 查询（补齐若仅有 request）；偏好持久化；`UcgPushRegistrationService` / `appPushBootstrapProvider` 门闸。
- 依赖既有：`Permission.notification` / iOS request channel、`/app/api/push/register|unregister`、predict-imminent pending（关通知后 pending 仍可同步，扇出无 token 自然跳过）。
- Web：不出横条、设置入口可隐藏或进入后提示不支持。
- 对照基线 `openspec/specs/v2.1.0.md` 与未归档 `android-china-push-predict-imminent` 的全局推送约定。
