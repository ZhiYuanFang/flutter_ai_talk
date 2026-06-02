## Why

登录页当前在账号输入框下方直接展示「最近账号」ActionChip，视觉杂乱；且本地仅缓存账号字符串，选中后无法回填密码，与「一键选历史账号并登录」的预期不符。需要在不牺牲安全性的前提下，将历史凭据收进账号框下拉菜单，并用平台安全存储保存密码。

## What Changes

- 移除登录页账号框下方的「最近账号」标签与 ActionChip 列表。
- 在账号输入框右侧增加下拉箭头（仅当存在历史凭据时显示）；点击后在输入框附近弹出风格对齐登录页的小菜单，最多展示 5 条历史成功登录过的账号。
- 选中菜单项后同时回填账号与密码输入框，**不得**自动聚焦密码框；若当前账号框已 attach 键盘顶栏桥接，须同步 draft。
- 新增凭据历史存储：账号顺序仍用 SharedPreferences；密码写入 `flutter_secure_storage`（原生 Keychain/Keystore）；成功登录后写入/更新，上限 5 条且去重。
- 改密成功后清除该账号在本地安全存储中的密码（账号可仍保留在列表中，直至下次成功登录写入新密码）；注销账户时移除该账号的本地凭据条目。
- 切换账号时**不得**清除登录凭据历史（便于多账号切换）。
- 从 v1 仅账号列表迁移：旧用户选中历史账号时若本地无密码，仅回填账号，待再次成功登录后补齐密码。

## Capabilities

### New Capabilities

- `login-credential-history`：定义登录页历史凭据 UI（下拉菜单）、本地存储分层（顺序 + 安全密码）、生命周期（写入/清除/上限 5）及与改密、注销、切换账号的衔接规则。

### Modified Capabilities

- `username-password-auth`：补充成功登录后须记住最近凭据、登录页须提供历史凭据选择与回填的规范性要求（不改变现有校验与 `username_login` 契约）。

## Impact

- **Flutter UI**：`app/lib/ui/login_screen.dart`（移除 Chip、suffix 箭头、弹出菜单与回填逻辑）。
- **会话/存储**：重构或扩展 `app/lib/session/account_history_store.dart`（或新建 `credential_history_store.dart`）；`change_password_screen.dart` 改密成功后清除本地密码；注销流程清除对应凭据。
- **依赖**：新增 `flutter_secure_storage`。
- **测试**：更新/扩展凭据 store 单元测试（条数、去重、改密清除语义）。
- **OpenSpec 基线**：新增 `login-credential-history`；`username-password-auth` delta。
