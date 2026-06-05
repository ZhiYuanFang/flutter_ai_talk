## Context

当前登录页（`login_screen.dart`）提供账号密码表单与「微信登录」按钮；`RemoteAuthRepository.signInWithWeChat()` 调用 `POST /device/app/api/login`，成功后经 `_persistLoginData` 持久化 token 并设置 `SignInChannel.wechat`。`SignInChannel` 现有 `device`、`wechat`、`username`、`unknown`，无 Apple 渠道。

iOS 微信授权（`wechat_impl_mobile.dart`）在 `!await _fluwx.isWeChatInstalled` 时直接抛出 `WeChatAuthException('未安装微信')`；登录页仍展示微信按钮，用户点击后失败，违反 App Store 指南 4.2.3(i) 所要求的「不得将安装微信作为完成登录的唯一路径」体验。产品决策：**未安装微信时隐藏微信登录入口**，用户改用 Sign in with Apple 与账号密码；**不**实现应用内网页 OAuth 回退。

`prepare_ios_project.sh` 当前将 `NSMicrophoneUsageDescription` 默认设为「需要麦克风权限以支持语音输入与录音」，缺少审核要求的**具体用途与示例**，触发指南 5.1.1(ii) 拒收。

Apple App Store 指南 4.8 要求：提供第三方登录（微信）的 iOS 应用必须同时提供 Sign in with Apple。本变更覆盖 **flutter_ai_talk** 客户端全部三项审核修复；后端 `go_ai_talk`（`d:\work\go_ai_talk`）须先完成 Phase 1：`POST /device/app/api/apple_login`、Apple JWT 校验、`wx.apple_sub` 列、绑定 API（`apple/bind`、`wx/bindwx`）、profile 绑定状态字段。

产品明确：

- 用户**可以**在已登录状态下可选绑定第二登录方式（Apple-only → 绑微信；WeChat-only → 绑 Apple）。
- 用户**可以**仅使用单一登录方式，不绑定。
- **限制**：若曾分别以 Apple、微信各独立登录并产生两个 `wxId`，**不得**事后合并；绑定失败时客户端须明确提示。
- **未安装微信**：隐藏微信登录按钮；不展示错误 Toast；不实现 Safari / in-app 网页 OAuth。

## Goals / Non-Goals

**Goals:**

- iOS 登录页在展示微信登录时，同时展示 Sign in with Apple 按钮。
- 实现 `AuthRepository.signInWithApple()`，将 Apple `identityToken` 提交 `POST /device/app/api/apple_login`（附 `platform: ios`）。
- 服务端/客户端身份仅以 Apple JWT 内 `sub` 为准；客户端**不**持久化或上传 Apple 邮箱。
- 成功登录复用 `_persistLoginData` 与现有会话链路；设置 `SignInChannel.apple`。
- 用户取消授权时 Toast 提示，不写 token、不覆盖有效会话。
- 账号管理：`account_management_sheet` 支持 Apple-only「绑定微信」、WeChat-only「绑定 Apple」；双绑后只读展示。
- 绑定失败（`ErrAppleSubTakenByOther`、`ErrUnionIDTakenByOther`、`ErrAccountMergeConflict`）展示可理解文案，说明无法合并两个已独立创建的账号。
- 记录 iOS Xcode Capability 与 CI entitlement 配置要点。
- 将 `NSMicrophoneUsageDescription` 更新为含具体育儿语音输入示例的中文说明；CI 可通过 `IOS_MICROPHONE_USAGE_DESCRIPTION` 覆盖。
- 登录页在渲染微信入口前检测 `fluwx.isWeChatInstalled`；未安装时隐藏微信按钮；已安装时保持 fluwx SDK 路径。

**Non-Goals:**

- iOS 未安装微信时的应用内浏览器 / `ASWebAuthenticationSession` / Safari 网页 OAuth 回退（产品明确拒绝）。
- 合并两条已独立存在的完整账号（后端拒绝；客户端不尝试 workaround）。
- Android 强制展示 Apple 按钮（仅 iOS 合规要求）。
- 在本仓库实现 `go_ai_talk` 后端。
- 存储 Apple 邮箱或依赖 Apple 提供的姓名作为账号标识。
- 修改 Android 未安装微信时的错误处理行为（不在本次审核范围；若与 iOS 一致隐藏入口可顺带对齐，非必须）。

## Decisions

### Apple Sign in with Apple

1. **依赖：`sign_in_with_apple`**
   - 使用官方维护的 `sign_in_with_apple` 插件发起 iOS 系统授权并获取 `identityToken`。
   - 备选：手写 `AuthenticationServices` Platform Channel — 未采用，维护成本高且无必要。

2. **网关契约（客户端侧假设，后端 Phase 1 实现）**
   - 请求：`POST /device/app/api/apple_login`，body `{ "identityToken": "<JWT>", "platform": "ios" }`（键名 lowerCamelCase，与现有网关一致）。
   - 响应：与 `login` / `username_login` 相同 envelope，`data` 含 `accessToken`、`refreshToken`、可选 `deviceNo`。
   - 服务端仅验证 JWT 签名与 `sub`，映射/创建用户于 `wx.apple_sub`；**不得**将 Apple 邮箱写入业务库或作为登录主键。

3. **Repository 分层**
   - `AuthRepository` 新增 `signInWithApple()`。
   - `RemoteAuthRepository.signInWithApple()`：调用 `SignInWithApple.getAppleIDCredential`，取 `identityToken`（UTF-8 字符串），`postJsonEnvelope` 后 `_persistLoginData`，`signInChannelProvider.setApple()`。
   - 取消：`SignInWithAppleAuthorizationException` 且 `code == AuthorizationErrorCode.canceled` → Toast「已取消 Apple 登录」类文案。

4. **`SignInChannel.apple`**
   - 枚举新增 `apple`，`wireValue` 为 `'apple'`；`SignInChannelNotifier` 新增 `setApple()`。

5. **登录页 UI**
   - 使用 `defaultTargetPlatform == TargetPlatform.iOS` 控制 Apple 按钮可见性。
   - 按钮置于微信登录旁或上方，使用 `SignInWithAppleButton`（或风格对齐的 `OutlinedButton` + Apple 图标）。

6. **iOS Entitlements 与 CI**
   - 在 `ios/Runner/Runner.entitlements` 启用 **Sign in with Apple**（`com.apple.developer.applesignin`）。
   - 发布前确认 entitlements 与 App ID Capability 一致。

### Apple ↔ 微信可选绑定

7. **绑定 API（Bearer）**
   - `AuthRepository` 新增 `bindApple({required String identityToken})` → `POST /device/app/api/user/apple/bind`。
   - `AuthRepository` 新增 `bindWx({required String jsCode})`（或复用/重命名现有 `bindUsernameWx` 调用路径）→ `POST /device/app/api/user/wx/bindwx`（泛化，不限用户名账号）。
   - 绑定成功后刷新 profile（`isAppleBound`、`isWxBound`、`authProviders`）；**不**切换 `wxId` 或重发登录。

8. **账号管理 UI（`account_management_sheet`）**
   - 读取 profile：仅 Apple → 展示「绑定微信」；仅微信 → 展示「绑定 Apple」（iOS）；双绑 → 只读状态文案。
   - Apple 绑定：复用 `sign_in_with_apple` 取 `identityToken` 后调 `bindApple`。
   - 微信绑定：复用现有 `obtainWxCode()` 后调 `bindWx`。
   - 冲突错误映射用户文案，例如：「该 Apple/微信账号已关联其他胖宝账号，无法合并两个已独立创建的账号」。

9. **单一登录仍允许**
   - 不强制绑定；未绑定时功能与变更前等价（各渠道独立使用）。

### iOS 麦克风用途说明（指南 5.1.1(ii)）

10. **文案内容**
    - 默认中文说明（写入 `prepare_ios_project.sh` 与文档）：
      > 胖宝需要访问您的麦克风，以便将您说出的育儿记录（例如「宝宝刚刚喝了 120ml 奶」）转换为文字并保存。麦克风仅用于语音输入，不会在后台录音或用于广告。
    - 须同时说明：**为何**需要麦克风、**具体使用场景示例**、**不会**后台录音或用于广告。

11. **CI 注入**
    - 环境变量 `IOS_MICROPHONE_USAGE_DESCRIPTION` 非空时，`prepare_ios_project.sh` 将其写入 `ios/Runner/Info.plist` 的 `NSMicrophoneUsageDescription`；否则使用上述默认文案。
    - 现有 `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION` 逻辑不变；若审核后续要求 speech 说明也需示例，可在独立 follow-up 中处理。

12. **实现位置**
    - 仅修改 `app/tool/ci/prepare_ios_project.sh` 默认值及 CI 文档/README 中的变量说明；不在 Dart 源码硬编码 plist 字符串（与现有 CI 模式一致）。

### iOS 微信登录可见性（指南 4.2.3(i)）

13. **检测时机与 API**
    - 在 `login_screen.dart` 进入页面或 `initState` 时异步调用 `fluwx.isWeChatInstalled`（与现有 `wechat_impl_mobile.dart` 所用 `Fluwx` 实例一致）。
    - 将结果存入本地 state（如 `_weChatInstalled`），在 `build` 中条件渲染微信登录按钮。

14. **未安装微信时的 UI 行为**
    - **隐藏**「微信登录」按钮及相关分隔/文案（若仅服务于微信入口）。
    - **不**弹出「未安装微信」Toast 或错误对话框（用户未点击不可用入口）。
    - 页面仍须展示 Sign in with Apple（iOS）与账号密码表单，满足未安装微信用户的登录路径。

15. **已安装微信时的行为**
    - 展示微信登录按钮；点击后沿用现有 `fluwx` SDK `authBy(NormalAuth(...))` 路径，**不**强制网页 OAuth。
    - `wechat_impl_mobile.dart` 中 `!isWeChatInstalled` 分支理论上不应再被登录页触发；若账号管理等其它入口调用 `obtainWxCode()` 仍可能命中，保持现有错误提示即可（绑定场景假定已安装微信）。

16. **平台范围**
    - iOS 为审核必达路径；Android 若当前始终展示微信按钮，可顺带采用相同「未安装则隐藏」逻辑以保持一致，但非本变更硬性要求。

17. **明确排除**
    - **不得**新增 `flutter_web_auth_2`、`url_launcher` in-app OAuth、`WECHAT_OAUTH_REDIRECT_URI` iOS 原生回退配置，或 `wechat_oauth_common.dart` 提取 solely 为 iOS fallback 服务。

## Risks / Trade-offs

- **[Risk] Phase 1 未就绪导致 Apple 登录/绑定联调失败** → Mitigation：tasks 标明后端前置；staging 网关；合并前确认 API 已部署。
- **[Risk] Entitlement 未配置导致 iOS Apple 授权失败** → Mitigation：真机 smoke test；CI 检查清单。
- **[Risk] `isWeChatInstalled` 检测延迟导致按钮短暂闪现** → Mitigation：检测完成前不渲染微信按钮（或默认隐藏直至确认已安装）；避免先展示后隐藏的闪烁。
- **[Risk] 用户曾独立创建双账号后尝试绑定** → Mitigation：明确错误文案；spec 覆盖冲突场景。
- **[Trade-off] 未安装微信用户无法使用微信登录** → 由 Apple 登录 + 账号密码替代；符合产品决策与 4.2.3(i) 合规策略。
- **[Trade-off] 绑定 UI 仅 iOS 展示 Apple 绑定向** → Apple 登录本身仅 iOS 合规要求；WeChat 绑 Apple 亦仅 iOS 有意义。

## Migration Plan

1. **Phase 1（go_ai_talk，独立 PR）**：迁移 `wx.apple_sub`、实现 JWT 校验与 `apple_login`、绑定 API、profile 字段；staging 验证。
2. **Phase 2（本仓库）**：Apple 登录 + 账号管理绑定 — 依赖、entitlements、repository、channel、登录页 Apple 按钮、`account_management_sheet`；对接 staging API。
3. **Phase 3（本仓库，可与 Phase 2 同 PR）**：
   - 更新 `prepare_ios_project.sh` 麦克风默认文案；CI 文档补充 `IOS_MICROPHONE_USAGE_DESCRIPTION`。
   - 在 `login_screen.dart` 实现 `isWeChatInstalled` 检测与微信入口条件展示。
4. **发布**：后端 Phase 1 先行或同版本；三项修复一并提交 App Store 审核。
5. **回滚**：可分别回滚 Apple 按钮、绑定 UI、微信可见性逻辑、麦克风文案；已登录 session 不受影响。

## Open Questions

- `apple_login` 请求体是否需额外字段（如 `deviceNo`）——默认仅 `identityToken` + `platform`；联调时与后端确认。
- `NSSpeechRecognitionUsageDescription` 是否需同步加入示例——当前审核项仅点名麦克风；若二次拒收再补。
- 绑定冲突错误码到用户文案的精确映射——实现时与后端 envelope `code` 对齐。
- Android 是否同步隐藏未安装时的微信按钮——默认可选对齐，不阻塞 iOS 审核。
