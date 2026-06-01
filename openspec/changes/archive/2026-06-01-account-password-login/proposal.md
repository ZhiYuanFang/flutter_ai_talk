## Why

当前客户端基线为仅微信登录，已无法覆盖账号密码登录、账号注册、改密与微信账号补齐用户名密码等新业务流程，且与后端已新增接口不一致。现在需要恢复并扩展登录体系，使用户可在微信与账号密码两种路径之间按场景完成建会话与账号管理，降低登录失败与绑定阻塞。

## What Changes

- 新增账号密码主登录能力：客户端支持通过 `POST /device/app/api/username_login` 建立会话并持久化 `accessToken`/`refreshToken`。
- 新增用户名体系能力：支持注册、纯业务登录（不发 token）、改密、微信账户创建用户名密码、绑定微信、绑定设备号。
- 登录页从“仅微信登录”调整为“微信登录 + 账号密码登录”的双入口，并补充注册与错误提示路径。
- 统一账号字段规则：前端提交前执行 `account` 的 `trim + lowercase`，并校验 `^[a-z0-9_]{4,32}$`；`password` 校验长度 `6-64`。
- 会话与兼容策略保持：继续复用现有 token 刷新、`deviceNo` 缓存与登录后跳转主页流程。
- **BREAKING**：客户端“仅微信登录”的产品约束被替换为“双登录入口”；相关文档、文案与联调说明同步更新。

## Capabilities

### New Capabilities
- `username-password-auth`: 定义账号密码建会话、登录页双入口、账号字段校验与错误提示规范。
- `username-account-management`: 定义用户名注册、改密、微信绑定、设备绑定、微信账号补齐用户名密码等账号管理流程。

### Modified Capabilities
- （无）

## Impact

- 受影响代码：`app/lib/ui/login_screen.dart`、`app/lib/data/repositories.dart`、`app/lib/data/remote_auth_repository.dart`、`app/lib/providers/repositories.dart`、账号相关设置页与路由入口。
- 受影响接口：新增对 `/device/app/api/username_login`、`/device/app/api/user/username/*` 系列接口的前端联调；继续使用 `/device/app/api/login`、`/device/app/api/token/refresh`、`/device/app/api/user/get`。
- 会影响登录渠道状态与画像保存分支，需要明确账号密码登录对应的渠道枚举及回退语义。
- 文档与联调说明（README、OpenSpec）需从“仅微信登录”更新为“双路径登录与账号管理”。
