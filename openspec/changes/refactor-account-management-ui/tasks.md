## 1. Profile 数据层

- [x] 1.1 新增 `UserAccountProfile` 模型（`account`、`isWxBound`）及 gateway JSON 解析
- [x] 1.2 在 `AuthRepository` / `RemoteAuthRepository` 实现 `fetchUserProfile()`（`GET /device/app/api/user/profile`）
- [x] 1.3 新增 `userProfileProvider`（`FutureProvider`），未登录态安全处理

## 2. 账号管理玻璃 Sheet

- [x] 2.1 将 `_openAccountActions` 重构为 `showGlassAdaptiveBottomSheet`，移除 Material Sheet 与 AlertDialog 输入
- [x] 2.2 打开 Sheet 时 invalidate/await `userProfileProvider`，按 `account`/`isWxBound` 条件渲染列表项
- [x] 2.3 将「切换账号」「注销账户」移入 Sheet；从设置页顶层移除对应 tile
- [x] 2.4 移除联调项、绑定设备号、补齐密码、手动 jsCode 绑微信等旧入口
- [x] 2.5 更新「账号管理」tile subtitle 为产品向文案

## 3. 修改密码页

- [x] 3.1 新建 `change_password_screen.dart`（玻璃风格，只读 account + 旧/新密码）
- [x] 3.2 在 `app_router.dart` 注册 `/settings/change-password` 路由
- [x] 3.3 改密成功：仅 `sessionProvider.signOut()`，跳转 `/login?account=xxx` 并 toast
- [x] 3.4 `LoginScreen` 读取 query 参数预填账号输入框

## 4. 绑定微信 OAuth

- [x] 4.1 Sheet 内「绑定微信」调用 `weChatAuthClient.obtainWxCode()` + `bindUsernameWx`
- [x] 4.2 成功：`showGlassDialog` 提示绑定成功 + invalidate profile；取消：轻 toast
- [x] 4.3 `isWxBound == true` 时展示只读「已绑定微信」

## 5. 清理与验证

- [x] 5.1 确认设置页顶部「绑定宝宝」入口未改动
- [x] 5.2 区分改密重登与切换账号的 signOut 清理范围（切换仍全量清理）
- [x] 5.3 手工回归：纯微信用户 Sheet、账号改密重登、绑微信 OAuth、切换账号、注销
