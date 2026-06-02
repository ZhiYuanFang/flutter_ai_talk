## 1. 依赖与凭据存储层

- [x] 1.1 在 `app/pubspec.yaml` 添加 `flutter_secure_storage` 并按插件文档确认 Android/iOS 配置
- [x] 1.2 新建 `app/lib/session/credential_history_store.dart`：`CredentialEntry`、`loadEntries`、`rememberSuccessfulLogin`、`removePassword`、`removeAccount`，上限 5、去重、secure 键 `pangbao_cred_pw_v1::{account}`，顺序键 `pangbao_recent_accounts_v2`
- [x] 1.3 可选：从 v1 `pangbao_recent_accounts_v1` 一次性导入账号到 v2（无密码）；废弃或 thin-wrap 旧 `account_history_store.dart`
- [x] 1.4 扩展/迁移 `app/test/account_history_store_test.dart` 覆盖 5 条上限、去重、改密 `removePassword`、注销 `removeAccount`

## 2. 生命周期挂钩

- [x] 2.1 `login_screen.dart`：登录成功路径在进主页前调用 `rememberSuccessfulLogin(normalized, password)`；微信登录不得写入
- [x] 2.2 `change_password_screen.dart`：改密成功、`signOut` 前调用 `removePassword(account)`
- [x] 2.3 `account_management_sheet.dart`：`confirmAccountDeregistration` 成功路径对 profile.account 调用 `removeAccount`；确认 `_switchAccount` 不触碰凭据 store

## 3. 登录页 UI

- [x] 3.1 移除账号框下方「最近账号」标签与 ActionChip 区块
- [x] 3.2 有历史时账号框 `suffixIcon` 展示 `arrow_drop_down`；`_loading` 时禁用；无历史时不展示
- [x] 3.3 实现紧贴账号框的风格化小菜单（米色底、圆角 14、棕色文字），列出最多 5 条账号
- [x] 3.4 选中菜单项：回填账号+密码、清错误态、不自动聚焦密码框；同步 `keyboardInputBridgeController.updateDraft`
- [x] 3.5 注册页返回预填账号密码场景：仍仅在登录成功时写入 secure 凭据（保持现有 `_rememberAccount` 语义迁移到新 store）

## 4. 验证

- [x] 4.1 手工：有 2+ 历史账号，下拉选一项，账号密码均填好，点登录可进主页
- [x] 4.2 手工：改密重登后下拉选同账号，密码框为空或不含旧密码；用新密码登录成功后再次下拉可回填新密码
- [x] 4.3 手工：切换账号后回登录页，历史下拉仍在；注销后对应账号从下拉消失
- [x] 4.4 运行相关单元测试通过
