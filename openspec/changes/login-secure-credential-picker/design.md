## Context

登录页（`login_screen.dart`）在账号框下方用 ActionChip 展示 `account_history_store` 中的最近 3 个账号；存储仅用 SharedPreferences 键 `pangbao_recent_accounts_v1` 保存账号字符串，登录成功时 `pushRecentAccount` 写入。选中 Chip 仅回填账号，密码需手输。

产品要求：收起到账号框右侧下拉箭头；弹出紧贴输入框、风格对齐登录页（米色底 `#FBF8F3`、圆角 14、棕色文字）的小菜单；选中后回填账号+密码且不自动聚焦密码框；历史上限升至 5；密码须安全存储。

相关已有能力：`change_password_screen.dart` 改密成功后 `signOut` 并跳转 `/login?account=xxx`；`account_management_sheet.dart` 切换账号清 session/deviceNo/历史但不动账号历史 store。

## Goals / Non-Goals

**Goals:**

- 实现 `CredentialHistoryStore`（或重构 `account_history_store`）：账号顺序 + 安全密码分层存储，上限 5、LRU 去重。
- 登录页 UI：suffix 下拉箭头 + 风格化 `showMenu`/`MenuAnchor`；移除 inline Chip。
- 生命周期：登录成功写入；改密成功清除该账号密码；注销移除该账号条目；切换账号保留凭据历史。
- 与 `keyboardInputBridgeController` 同步回填 draft。
- Web 平台：接入 `flutter_secure_storage` 的 Web 实现；若某条目无密码则仅回填账号（与 v1 迁移一致）。

**Non-Goals:**

- 生物识别解锁、自动登录（无用户点击登录按钮）。
- 修改 `username_login` 或后端契约。
- 变更账号管理 Sheet / profile 接口（已在 `refactor-account-management-ui` 完成）。
- 在 URL query 或 SharedPreferences 中明文存密码。

## Decisions

1. **存储分层**
   - SharedPreferences：`pangbao_recent_accounts_v2`（`StringList`，最多 5，仅账号，规范化 `trim + lowercase`）。
   - `flutter_secure_storage`：键 `pangbao_cred_pw_v1::{account}` 存密码。
   - 备选：整包 JSON 加密 blob — 未采用，按账号删改密/注销更简单。
   - 备选：密码仍放 SharedPreferences — 未采用，违反安全要求。

2. **门面 API**（`app/lib/session/credential_history_store.dart`）
   - `loadEntries()` → `List<CredentialEntry>`（account + password?，按顺序）。
   - `rememberSuccessfulLogin(account, password)` → 更新顺序并写 secure password。
   - `removePassword(account)` → 删 secure key，保留顺序项。
   - `removeAccount(account)` → 删顺序项 + secure key。
   - 保留或废弃 `account_history_store.dart`：建议合并到新 store，登录页改 import，测试迁移。

3. **登录页菜单**
   - 使用 `showMenu` + `RelativeRect` 锚定在账号 `TextField` 下方，或 `MenuAnchor`；菜单 `ShapeDecoration` 圆角 14、背景 `#FBF8F3`、文字 `#4A3428`、浅描边。
   - `_recentEntries.isEmpty` 时不渲染 suffix 箭头。
   - 选中回调：填 `_accountCtrl` / `_passwordCtrl`，清错误态，**不** `requestFocus` 密码框；对当前 attach 的 controller 调 `keyboardInputBridgeController.updateDraft`。

4. **改密衔接**
   - 在 `ChangePasswordScreen._submit` 成功、`signOut` 之前调用 `removePassword(profile.account)`。
   - 跳转仍仅 query 预填账号；用户手输新密码，下次登录成功再 `rememberSuccessfulLogin`。

5. **注销衔接**
   - `confirmAccountDeregistration` 成功路径：若 profile 有 `account`，调用 `removeAccount(account)`（需在 signOut 前读 profile 或从 session 侧获取）。

6. **切换账号**
   - `_switchAccount` **不**调用凭据 store 清除方法。

7. **条数上限**
   - 常量 `kCredentialHistoryLimit = 5`；超出时 drop 最旧项并 `removeAccount` 被淘汰账号的 secure key。

8. **v1 迁移**
   - 首次启动读 v1 key 若 v2 空，可一次性导入账号到 v2（无密码）；不强制删 v1。

## Risks / Trade-offs

- **[Risk] Web 上 secure storage 强度弱于原生** → Mitigation：spec 标明原生必达；Web 仍用插件、无密码时降级仅填账号。
- **[Risk] 改密未清密码导致回填旧密码** → Mitigation：改密成功路径单测 + 手工用例；任务中显式挂钩 `removePassword`。
- **[Risk] 键盘顶栏 draft 与输入框不同步** → Mitigation：回填后按 binding 更新 draft。
- **[Trade-off] 本地存密码即使用户设备被攻破可泄露** → 行业常见「记住密码」权衡；已用 Keychain/Keystore，不做 root 检测。

## Migration Plan

1. 添加 `flutter_secure_storage` 依赖并配置 Android/iOS（按插件文档 min SDK）。
2. 实现新 store，登录页改用 `loadEntries` / `rememberSuccessfulLogin`。
3. 改密、注销挂钩清除逻辑。
4. 移除 Chip UI，加下拉菜单。
5. 更新/新增 store 单元测试；手工回归登录、改密、切换、注销。

回滚：还原 UI 与 store 调用，保留 v2 key 无害；可回退依赖。

## Open Questions

- 无（产品侧已确认：5 条、安全存储、小菜单、不自动聚焦密码）。
