## 0. 前置依赖（go_ai_talk，独立仓库）

- [x] 0.1 在 `go_ai_talk` 完成 Phase 1：`wx.apple_sub` 列迁移、Apple `identityToken` JWT 校验（仅信任 `sub`）、`POST /device/app/api/apple_login`、`POST /device/app/api/user/apple/bind`、`POST /device/app/api/user/wx/bindwx`、profile `isAppleBound`/`authProviders`（**本仓库不实现，联调前须已部署**）

## 1. 依赖与 iOS 工程配置

- [x] 1.1 在 `app/pubspec.yaml` 添加 `sign_in_with_apple` 依赖并 `flutter pub get`
- [x] 1.2 在 iOS 工程启用 Sign in with Apple Capability，确认 `Runner.entitlements` 含 `com.apple.developer.applesignin`；在 README 或发布检查清单中记录 CI/IPA 构建须校验该 entitlement

## 2. 数据层与登录渠道（Apple）

- [x] 2.1 在 `AuthRepository`（`repositories.dart`）声明 `signInWithApple()`
- [x] 2.2 在 `RemoteAuthRepository` 实现 `signInWithApple()`：获取 `identityToken` → `POST /device/app/api/apple_login`（`identityToken`、`platform: ios`）→ `_persistLoginData`；不上传/存储 Apple 邮箱
- [x] 2.3 处理用户取消：映射 `AuthorizationErrorCode.canceled` 为可 Toast 的业务错误，不写 token
- [x] 2.4 `SignInChannel` 枚举与 `SignInChannelStore`/`SignInChannelNotifier` 新增 `apple` 与 `setApple()`

## 3. 登录页 UI（Apple，iOS）

- [x] 3.1 在 `login_screen.dart` 于微信登录旁（或协调布局）增加 Sign in with Apple 按钮，仅 iOS 可见（`defaultTargetPlatform == TargetPlatform.iOS`）
- [x] 3.2 实现 `_onAppleLogin`：loading 态、调用 `auth.signInWithApple()`、成功导航与微信/账号登录一致；失败/取消 Toast
- [x] 3.3 确认 Android/Web 不展示 Apple 按钮，微信与账号密码入口行为不变

## 4. 账号绑定（Apple ↔ 微信，iOS）

- [x] 4.1 在 `AuthRepository` 声明 `bindApple` 与 `bindWx`（或泛化现有 bind 方法）；`RemoteAuthRepository` 实现 `POST /device/app/api/user/apple/bind` 与 `POST /device/app/api/user/wx/bindwx`（Bearer）
- [x] 4.2 在 `account_management_sheet.dart`：依据 profile `isAppleBound`/`isWxBound`/`authProviders` 展示绑定入口或只读状态（Apple-only →「绑定微信」；WeChat-only →「绑定 Apple」；双绑 → 只读）
- [x] 4.3 绑定 Apple：调 `sign_in_with_apple` 取 `identityToken` → `bindApple`；绑定微信：调 `obtainWxCode()` → `bindWx`；成功后刷新 profile
- [x] 4.4 映射 `ErrAppleSubTakenByOther`、`ErrUnionIDTakenByOther`、`ErrAccountMergeConflict` 为明确 Toast/文案：无法合并两个已独立创建的账号

## 5. iOS 麦克风用途说明（指南 5.1.1(ii)）

- [x] 5.1 更新 `app/tool/ci/prepare_ios_project.sh`：`NSMicrophoneUsageDescription` 默认值改为含育儿语音示例的中文说明（见 design）；保留 `IOS_MICROPHONE_USAGE_DESCRIPTION` 环境变量覆盖
- [x] 5.2 在 `app/README.md` 或 iOS 发布检查清单中记录 `IOS_MICROPHONE_USAGE_DESCRIPTION` 用途与建议文案
- [x] 5.3 本地或 CI 执行 `prepare_ios_project.sh` 后确认 `ios/Runner/Info.plist` 含更新后的 `NSMicrophoneUsageDescription`

## 6. 微信登录可见性（指南 4.2.3(i)）

- [x] 6.1 在 `login_screen.dart`：`initState` 或等价时机异步调用 `fluwx.isWeChatInstalled`，结果存入 state；检测完成前默认不展示微信按钮（避免闪烁）
- [x] 6.2 当 `isWeChatInstalled == false` 时隐藏「微信登录」按钮及相关仅服务于微信的 UI 元素；**不得**弹出「未安装微信」Toast
- [x] 6.3 当 `isWeChatInstalled == true` 时展示微信按钮，点击后沿用现有 `fluwx` SDK 路径；**不得**新增应用内网页 OAuth / `flutter_web_auth_2` 回退
- [x] 6.4 未安装微信时确认页面仍展示 Sign in with Apple（iOS）与账号密码表单，用户可正常登录

## 7. 验证与文档

- [x] 7.1 iOS 真机联调：Apple 登录成功持久化 token 并进入主页；取消授权 Toast；后端未部署时错误提示可理解
- [x] 7.2 iOS 真机（**未安装微信**）：微信登录按钮不可见；无「未安装微信」Toast；Apple 登录与账号密码登录可用
- [x] 7.3 iOS 真机（**已安装微信**）：微信登录按钮可见且仍走 fluwx SDK，行为与变更前一致
- [x] 7.4 账号绑定：Apple-only 绑微信成功；WeChat-only 绑 Apple 成功；双绑后只读；曾独立创建双账号时绑定失败且文案明确
- [x] 7.5 在 PR/变更说明中注明本变更覆盖 App Store 三项审核修复：4.8 Apple 登录、4.2.3(i) 未安装微信时隐藏微信入口、5.1.1(ii) 麦克风用途说明
