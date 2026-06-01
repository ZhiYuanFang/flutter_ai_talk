## Why

当前登录页的真实可用入口仍是胖宝号（设备号）登录，而微信登录仅展示为未开放占位，和产品目标「仅保留微信登录」不一致。现在需要把登录入口、登录文案与鉴权能力统一到微信授权链路上，同时移除设备号登录能力，避免用户走到不再支持的旧路径。

## What Changes

- 登录页必须仅保留微信登录入口，不再展示胖宝号输入框、设备号登录按钮或引导文案。
- 客户端必须以 `AuthRepository.signInWithWeChat()` 作为唯一交互式登录路径；微信授权成功后继续沿用现有网关 `POST /device/app/api/login` 完成会话建立。
- 客户端必须移除对外暴露的设备号登录能力，包括 `signInWithDeviceNo()` 所代表的产品能力、登录页设备号提交流程以及相关提示文案。
- Web 端不得再在登录页清空微信 OAuth 回调结果并提示“请使用胖宝号登录”；回调完成后应回到登录页继续微信登录链路。
- 文档与配置说明必须同步更新，明确当前仅支持微信登录，设备号登录仅可作为历史兼容数据概念存在，不再作为用户可触发登录方式。
- **BREAKING**：用户无法再通过 `POST /device/app/api/device_login` 对应的客户端登录流程进入系统；任何依赖设备号人工输入登录的旧操作方式将失效。

## Capabilities

### New Capabilities
- `wechat-only-sign-in`: 定义登录页仅提供微信登录、微信授权回调继续登录、以及设备号登录入口移除后的用户可见行为与错误处理。

### Modified Capabilities
- （无）当前仓库根目录 `openspec/specs/` 为空，本变更以新增能力规格承载要求。

## Impact

- 代码：`app/lib/ui/login_screen.dart`、`app/lib/data/repositories.dart`、`app/lib/data/remote_auth_repository.dart`、`app/lib/wechat/**`、`app/lib/ui/wechat_oauth_callback_screen.dart`、相关 provider 与 README。
- 接口：客户端不再触发 `POST /device/app/api/device_login` 登录流程；继续使用 `POST /device/app/api/login` 作为微信登录建会话接口。
- 兼容性：`deviceNo` 仍可能作为登录成功后的业务标识存在，用于历史、画像等后续接口；移除的是“设备号登录能力”，不是“deviceNo 数据字段”。
- 风险：现有 `SignInChannel.device` 还参与宝宝资料保存分支选择，移除登录能力时需明确旧会话与历史数据的兼容策略。
