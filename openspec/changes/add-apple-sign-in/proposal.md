## Why

Apple App Store 审核对当前 iOS 版本提出三项合规问题，需在同一客户端变更中一并解决后再提交审核：

1. **指南 4.8**：当应用提供第三方登录（微信）时，必须同时提供「通过 Apple 登录」（Sign in with Apple）。
2. **指南 4.2.3(i)**：不得要求用户安装微信客户端才能完成登录；未安装微信的 iOS 用户须可通过其他已提供的登录方式（Apple 登录、账号密码）进入应用，且**不得**展示无法使用的微信登录入口。
3. **指南 5.1.1(ii)**：`NSMicrophoneUsageDescription` 须说明麦克风具体用途并给出使用示例，不得使用笼统文案。

当前登录页仅有微信与账号密码入口；iOS 在未安装微信时仍展示微信按钮且点击后失败；麦克风权限说明过于笼统——均不满足上架合规。

## What Changes

### Sign in with Apple（指南 4.8）

- 在 `pubspec.yaml` 增加 `sign_in_with_apple` 依赖。
- iOS 登录页在现有微信登录与账号密码入口旁增加「通过 Apple 登录」按钮（Android 可省略该按钮）。
- `AuthRepository` 新增 `signInWithApple()`，调用网关 `POST /device/app/api/apple_login`，请求体携带 Apple `identityToken`（服务端仅信任 JWT 内 `sub`，**不得**存储 Apple 邮箱）。
- `SignInChannel` 枚举与持久化新增 `apple` 渠道。
- 成功登录后沿用现有会话持久化链路（`accessToken`、`refreshToken`、`deviceNo`、登录状态）。
- 用户取消 Apple 授权时展示可理解 Toast，不得写入错误 token 或覆盖有效会话。

### Apple ↔ 微信可选账号绑定

- **Apple-only 用户**（iOS）：在账号管理可「绑定微信」，调用泛化 `POST /device/app/api/user/wx/bindwx`（Bearer + `jsCode`）。
- **WeChat-only 用户**（iOS）：在账号管理可「绑定 Apple」，调用 `POST /device/app/api/user/apple/bind`（Bearer + `identityToken`）。
- **双绑完成**：账号管理展示只读绑定状态（依据 profile `isAppleBound` / `isWxBound` / `authProviders`）。
- **不可合并**：若用户曾分别以 Apple、微信各独立登录并产生两个 `wxId`，事后绑定将失败；客户端须展示明确提示（标识符已被其他账号占用 / 无法合并两个已独立创建的账号）。
- 用户**仍可**仅使用单一登录方式，不绑定第二方式。

### iOS 麦克风用途说明（指南 5.1.1(ii)）

- 更新 `app/tool/ci/prepare_ios_project.sh` 写入 `Info.plist` 的 `NSMicrophoneUsageDescription` 默认文案，须包含具体育儿语音输入示例（见 design）。
- CI/发布流程支持通过 `IOS_MICROPHONE_USAGE_DESCRIPTION` 环境变量覆盖该文案。

### iOS 微信登录可见性（指南 4.2.3(i)）

- 登录页在展示「微信登录」入口前，须检测 `fluwx.isWeChatInstalled`（iOS；Android 若现有逻辑一致则同步）。
- 当设备**未安装**微信时，**隐藏**微信登录按钮/入口；**不得**实现应用内浏览器 / Safari 网页 OAuth 回退。
- 未安装微信时，用户通过 **Sign in with Apple** 与 **账号密码** 登录；隐藏状态下**不得**弹出「未安装微信」类错误 Toast。
- 当设备**已安装**微信时，继续展示微信登录按钮并沿用现有 `fluwx` SDK 授权路径。

### 实现顺序（跨仓库）

1. **Phase 1**（`go_ai_talk`，独立仓库）：`POST /device/app/api/apple_login`、Apple JWT 校验、`wx.apple_sub` 列、`apple/bind` 与 `wx/bindwx` 绑定 API、profile 绑定状态字段；返回与微信/账号登录相同 token 形态。
2. **Phase 2**（本变更）：Flutter 客户端 Apple 登录与账号管理绑定 UI。
3. **Phase 3**（本变更，可与 Phase 2 同 PR 合并）：麦克风 usage string、登录页微信入口按安装状态条件展示。

## Capabilities

### New Capabilities

- `apple-sign-in`：定义 iOS 登录页 Apple 入口、`signInWithApple` 与 `apple_login` 网关契约、`SignInChannel.apple`、授权取消/失败提示、会话持久化。
- `apple-wechat-account-bind`：定义账号管理中 Apple↔微信可选绑定、`bindApple` / 泛化 `bindwx` 客户端契约、双绑只读态、独立双账号不可合并时的错误提示。
- `ios-microphone-usage-string`：定义 iOS `NSMicrophoneUsageDescription` 的具体用途说明、示例文案与 CI 注入方式。
- `ios-wechat-login-visibility`：定义登录页按 `isWeChatInstalled` 条件展示/隐藏微信入口；未安装时禁止网页 OAuth 回退；已安装时保持 fluwx 路径。

### Modified Capabilities

- `username-password-auth`：更新登录页入口规范性要求——当提供微信登录时，iOS 必须同时提供 Sign in with Apple（与账号密码入口并存）；微信入口在未安装微信时不得展示。

## Impact

- **Flutter 客户端**：`login_screen.dart`（Apple 按钮、微信入口可见性检测）、`remote_auth_repository.dart`、`repositories.dart`（`AuthRepository` 接口）、`sign_in_channel_provider.dart`、`sign_in_channel_store.dart`；`account_management_sheet.dart`（绑定入口与状态）；`pubspec.yaml` 新增 `sign_in_with_apple`。
- **iOS 工程**：Xcode Capability「Sign in with Apple」entitlement；`Info.plist` 麦克风用途说明；CI/发布流程须在 design 中记录 entitlement 与 `IOS_MICROPHONE_USAGE_DESCRIPTION` 校验要点。
- **后端依赖**（`go_ai_talk`，本仓库不实现）：`wx.apple_sub` 字段、Apple identity token JWT 校验、网关 `apple_login` / `apple/bind` / `wx/bindwx` 端点；客户端 Phase 2 依赖 Phase 1 已部署。
- **不在范围**：iOS 未安装微信时的网页 OAuth / `ASWebAuthenticationSession` 回退；合并两条已独立存在的完整账号（后端拒绝，客户端仅提示）；Android 强制展示 Apple 按钮。
