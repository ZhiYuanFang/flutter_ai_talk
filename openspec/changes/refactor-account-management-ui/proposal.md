## Why

当前设置页账号相关能力分散（切换账号、注销、改密、绑微信各自独立入口），账号管理弹窗仍使用 Material BottomSheet 与 AlertDialog，且暴露「绑定设备号」「微信补齐密码」「业务登录校验」等联调/后端概念，与面向用户的产品体验不符。后端已提供 `GET /device/app/api/user/profile`（返回 `account`、`isWxBound`），可驱动条件化账号管理 UI，现需统一信息架构、对接新接口并全面玻璃拟态化。

## What Changes

- 将**切换账号**、**注销账户**收进**账号管理**玻璃 BottomSheet；设置页顶层仅保留「账号管理」入口。
- 设置页顶部**保留**「绑定宝宝」入口；账号管理内**不再**展示绑定宝宝。
- 对接 `GET /device/app/api/user/profile`：`account` 非空时展示「修改密码」；`isWxBound` 驱动「绑定微信 / 已绑定微信」。
- 新建**修改密码**全屏页（玻璃风格）：只读展示当前 `account`；成功后**强制重新登录**并跳转 `/login?account=xxx` 预填账号（不清宝宝/历史缓存）。
- 绑定微信改为调起微信 OAuth 获取 `code` 后提交服务端，成功后玻璃弹框提示；已绑定则只读展示，不可改绑。
- **移除**用户可见的：绑定设备号、微信补齐用户名密码、业务登录校验（联调）入口。
- 补充 `ui-guidelines`：弹层/账号管理须走玻璃 overlay，禁止向用户暴露联调选项。

## Capabilities

### New Capabilities

- `user-account-profile`：定义 `GET /device/app/api/user/profile` 客户端契约及 `account`/`isWxBound` 在账号管理、改密页的消费规则。

### Modified Capabilities

- `username-account-management`：移除补齐密码/绑设备/联调用户场景；改密独立页与改密后强制重登；绑微信 OAuth 流程与条件展示。
- `ui-guidelines`：账号管理玻璃 Sheet、用户文案与禁止联调项等 UI 约束补充。

## Impact

- **Flutter UI**：`settings_screen.dart`（Sheet 重构、移除顶层切换/注销）、新建 `change_password_screen.dart`、`login_screen.dart`（query 预填 account）、`app_router.dart`（新路由）。
- **数据层**：`AuthRepository` / `RemoteAuthRepository` 新增 `fetchUserProfile`；新增 `UserAccountProfile` 模型与 `userProfileProvider`。
- **微信**：复用 `WeChatAuthClient.obtainWxCode()` + `bindUsernameWx`。
- **OpenSpec 基线**：`username-account-management`、`ui-guidelines` delta；新增 `user-account-profile`。
- **无后端变更**；仓储层 `createUsernameForWx`、`bindUsernameDevice`、`loginUsernameBusiness` 可保留供内部/联调，但 UI 不再暴露。
