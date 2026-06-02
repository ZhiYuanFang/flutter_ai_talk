## ADDED Requirements

### Requirement: 客户端必须在本地安全记住最近成功登录的账号密码凭据
The client MUST persist up to five most recently successful username-password login credentials locally, with passwords stored only in platform secure storage.
客户端在账号密码登录成功后，必须将规范化后的 `account` 与对应 `password` 写入本地凭据历史；账号展示顺序最多保留 **5** 条（最近成功者优先、同账号去重）；**密码不得**写入 SharedPreferences 或明文日志，必须写入 `flutter_secure_storage`（iOS Keychain / Android Keystore；Web 使用插件提供的安全存储实现）。

#### Scenario: 账号密码登录成功写入凭据
- **WHEN** 用户通过 `username_login` 成功建立会话
- **THEN** 客户端必须调用凭据 store 更新该账号顺序位置
- **AND** 必须将该账号密码写入 secure storage

#### Scenario: 超过 5 条时淘汰最旧条目
- **WHEN** 写入第 6 个不同账号的成功凭据
- **THEN** 客户端必须仅保留最近 5 个账号的顺序
- **AND** 必须删除被淘汰账号在 secure storage 中的密码键

#### Scenario: 同一账号再次登录成功
- **WHEN** 某账号已在历史中且再次登录成功
- **THEN** 该账号必须移到顺序首位
- **AND** 必须更新 secure storage 中的密码为本次登录所用密码

### Requirement: 登录页必须通过账号框下拉菜单展示并回填历史凭据
The login screen MUST expose saved credentials via a dropdown anchored to the account field and MUST fill both account and password on selection without auto-focusing the password field.
登录页**不得**在账号输入框下方 inline 展示历史账号 Chip 或类似列表；当存在至少一条本地凭据历史时，账号输入框右侧必须展示向下箭头；用户点击箭头后必须在输入框附近弹出小菜单（视觉风格须对齐登录页：米色底、圆角约 14、棕色系文字），列出历史账号供选择；选中某条后必须同时回填账号与密码输入框，**不得**自动将焦点移至密码框。

#### Scenario: 无历史时不展示箭头
- **WHEN** 本地凭据历史为空
- **THEN** 账号输入框不得展示下拉箭头
- **AND** 页面不得展示「最近账号」类 inline 列表

#### Scenario: 有历史时弹出菜单并回填
- **WHEN** 本地存在凭据历史且用户点击账号框右侧箭头
- **THEN** 必须在输入框附近弹出菜单并列出历史账号（最多 5 条）
- **AND** 用户选中某账号后必须回填账号与密码字段
- **AND** 不得自动聚焦密码输入框

#### Scenario: 历史条目无本地密码时仅回填账号
- **WHEN** 用户选中一条仅有账号顺序、secure storage 无密码的条目（例如自 v1 迁移或改密后尚未重新登录）
- **THEN** 客户端必须回填账号
- **AND** 密码框必须置空或保持用户可编辑状态，不得填入过期密码

#### Scenario: 键盘顶栏桥接已 attach 时同步 draft
- **WHEN** 用户通过菜单回填且账号或密码框当前 attach 了 `keyboardInputBridgeController`
- **THEN** 回填后必须同步更新桥接 draft，使顶栏显示与输入框一致

### Requirement: 改密与注销必须使本地凭据与服务器状态一致
The client MUST invalidate or remove locally stored credentials when the user changes password or deactivates the account.
改密成功并强制重新登录前，必须清除该账号在 secure storage 中的密码（账号可仍保留在顺序列表中）；用户注销账户成功后，必须移除该账号在顺序列表与 secure storage 中的全部本地条目；切换账号（清 session 返回登录）**不得**清除凭据历史 store。

#### Scenario: 改密成功后清除本地密码
- **WHEN** 用户在改密页成功修改密码并即将 signOut 跳转登录页
- **THEN** 客户端必须删除该账号在 secure storage 中的密码
- **AND** 跳转登录页时仍可通过 query 预填账号但不得回填旧密码

#### Scenario: 注销成功后移除凭据条目
- **WHEN** 用户完成账户注销且本地 profile 含非空 `account`
- **THEN** 客户端必须从历史顺序与 secure storage 中移除该账号

#### Scenario: 切换账号保留凭据历史
- **WHEN** 用户在账号管理中选择切换账号并清本地会话
- **THEN** 客户端不得清除凭据历史 store 中的条目
