## 1. 鉴权抽象与仓储接口扩展

- [x] 1.1 在 `AuthRepository` 增加账号体系方法：`signInWithUsernamePassword`、`registerUsername`、`loginUsernameBusiness`、`bindUsernameWx`、`bindUsernameDevice`、`changeUsernamePassword`、`createUsernameForWx`。
- [x] 1.2 在 `RemoteAuthRepository` 实现匿名接口：`/device/app/api/username_login`、`/device/app/api/user/username/register`、`/device/app/api/user/username/login`。
- [x] 1.3 在 `RemoteAuthRepository` 实现 Bearer 接口：`/device/app/api/user/username/bindwx`、`/device/app/api/user/username/bind_device`、`/device/app/api/user/username/change_password`、`/device/app/api/user/wx/create_username`。
- [x] 1.4 复用并补强 `_persistLoginData()`，确保账号登录成功与微信登录一致地持久化 token 与处理 `deviceNo`。

## 2. 登录页双入口与输入校验

- [x] 2.1 重构 `LoginScreen` 为“微信 + 账号密码”双入口，补充账号输入框、密码输入框、注册入口与加载态禁用逻辑。
- [x] 2.2 实现账号字段规范化：`account` 提交前 `trim + lowercase`。
- [x] 2.3 实现本地校验：`account` 命中 `^[a-z0-9_]{4,32}$`，`password` 长度 `6-64`，校验失败不发请求并提示。
- [x] 2.4 将账号登录成功路径接入现有 `_afterLoginSuccess()`（刷新 `deviceNo`、加载画像、跳转主页）。

## 3. 登录渠道与兼容行为

- [x] 3.1 扩展 `SignInChannel` 增加 `username` 枚举与持久化解析。
- [x] 3.2 在账号登录成功后写入 `username` 渠道；保留 `device`、`wechat`、`unknown` 历史兼容读取。
- [x] 3.3 回归 `RemoteSettingsRepository.saveBaby()` 分支，确认 `username` 与 `wechat` 的保存策略一致且不误走 `device` 分支。

## 4. 账号管理入口与错误处理

- [x] 4.1 在设置页或账号相关入口接入改密、绑定微信、绑定设备、微信补齐用户名密码的调用路径（可分阶段隐藏 UI，但仓储能力必须可调）。
- [x] 4.2 统一异常提示：业务错误展示服务端 `message`，HTTP 错误展示网络错误，不出现过时“仅微信登录”文案。
- [x] 4.3 明确 `/device/app/api/user/username/login` 的首期触发场景；若暂不开放 UI，需保留可测试调用点与注释。

## 5. 文档与验证

- [x] 5.1 更新 `app/README.md` 登录章节与接口联调说明，明确双登录入口与账号规则。
- [x] 5.2 补充联调清单：主登录、注册、改密、绑定微信、绑定设备、微信补齐用户名密码、token 刷新回归。
- [x] 5.3 运行 `openspec status --change "account-password-login"`、必要静态检查与关键流程手测，确认变更可进入 `/opsx:apply`。
