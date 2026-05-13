## Why

当前 App 已通过网关 `POST /device/app/api/login` 完成「用 wxCode 换 JWT」的后端联调，但 `wxCode` 仍依赖 `--dart-define=WX_LOGIN_CODE` 手工注入，无法在真机与生产环境完成微信身份授权。需要在客户端接入微信开放平台能力，由用户在应用内发起授权并自动获取 `wxCode`，再调用既有登录接口，形成端到端可用的微信登录。

## What Changes

- 在 **Android** 接入微信 SDK（如 `fluwx` 或官方 SDK 封装），完成 AppID/Universal Link（或包名签名）配置，拉起微信授权并解析 `code`。
- 在 **iOS** 接入微信 iOS SDK（或 `fluwx`），配置 URL Scheme、Universal Links、LSApplicationQueriesSchemes 等，拉起微信并回调 `code`。
- 在 **Web** 接入微信网页授权（OAuth2.0：`snsapi_userinfo` / `snsapi_base` 视产品要求），通过重定向或弹窗获取 `code` 并回到应用路由。
- 统一抽象 **`AuthRepository.signInWithWeChat()`**：内部按平台取码，再调用现有 `RemoteAuthRepository` 网关登录；联调保留 `WX_LOGIN_CODE` 作为可选降级或 CI 用。
- 更新 **README / dart-define**：文档化 `WECHAT_APP_ID`、回调域名、Web `redirect_uri` 等配置方式；**不得**将 AppSecret 写入客户端仓库。
- **BREAKING**：登录按钮行为从「仅依赖环境变量」变为「优先走 SDK/OAuth」；未配置微信参数时应有明确错误提示而非静默失败。

## Capabilities

### New Capabilities

- `wechat-oauth-login`：覆盖三端获取 `wxCode`、错误与取消处理、与网关 `login` 的衔接及可配置项（AppId、Universal Link、Web redirect 等）。

### Modified Capabilities

- （无）全局归档 spec 目录为空；与本变更相关的历史需求见变更 `pangbao-app` 下 `auth-wechat-privacy`，本变更以新增能力为主，不在此重复 delta。

## Impact

- **依赖**：`fluwx` 或等价插件、iOS/Android 原生工程配置、微信开放平台移动应用 / 网站应用审核资料。
- **代码**：`RemoteAuthRepository`、`LoginScreen`、`AppEnv`、`AndroidManifest`/`Info.plist`/`web/index.html` 或路由回调页。
- **安全**：仅客户端保存 AppId 与合法回调；Secret 仅在后端使用（已有网关逻辑不变）。
