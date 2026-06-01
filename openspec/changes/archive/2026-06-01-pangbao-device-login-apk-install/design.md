## Context

当前 `LoginScreen` 仅支持微信登录（含 Web OAuth 恢复）；`RemoteAuthRepository` 调用 `POST /device/app/api/login` 并解析 token 与可选 `deviceNo`。Android 版本更新在 `version_prompt.dart` 中通过 `url_launcher` 打开外链，尚未实现「缓存下载 + 调起安装」。产品要求默认改为胖宝号登录，微信入口占位；Android 需贴近华为、小米、OPPO、vivo 等机型的安装体验。

## Goals / Non-Goals

**Goals:**

- 登录页默认「胖宝号登录」，对接 `POST /device/app/api/device_login`，请求体字段 **`device_no`**（与网关约定一致）；成功后复用现有 `persistTokens`、设备号缓存与进入首页流程。
- 微信登录按钮保留但点击仅 Toast：**「当前功能未开放」**，不调用 fluwx / 网页跳转 / 网关微信登录。
- Android：版本更新 APK 下载至**应用可写缓存/临时目录**，校验扩展名或 MIME 后通过 **FileProvider + Intent** 发起安装；声明必要权限与 `provider` 配置。
- iOS / Web：登录行为与微信拦截一致；版本更新路径不变（iOS App Store、Web 刷新）。

**Non-Goals:**

- 不实现微信登录重新开放后的灰度策略（仅拦截）。
- 不实现应用内增量更新、热更新、多 ABI split 包合并。
- 不要求绕过各厂商应用商店的「未知来源」系统页（仅引导用户完成系统设置后重试）。

## Decisions

1. **Auth 抽象**  
   在 `AuthRepository` 增加 `Future<void> signInWithDeviceNo(String deviceNo)`（或对 `device_no` 做 trim 后传入）。`RemoteAuthRepository` 使用现有匿名 `ApiClient` 调用 `POST /device/app/api/device_login`，JSON body：`{ "device_no": "<trimmed>" }`。响应字段解析与微信登录对齐（`accessToken`/`access_token`、`refreshToken`/`refresh_token`、`deviceNo`/`device_no`）。  
   **理由**：与现有会话层一致，避免重复解析逻辑。

2. **登录页布局**  
   首屏主区域：标题 + `TextField`（胖宝号）+「登录」主按钮；次区域：Outlined「微信登录」按钮。进入页面默认 `autofocus` 在胖宝号输入框（Web/Mobile 一致）。  
   **理由**：满足「默认登录方式」与操作路径最短。

3. **微信拦截**  
   `_onWeChatLogin` 首行 `ref.read(apiToastProvider.notifier).state = '当前功能未开放'; return;`。**删除或短路** Web 自动 OAuth 恢复中对微信登录的自动触发：若仅保留胖宝号自动登录，则 `initState` 中 `_tryResumeWebOAuth` 在「微信未开放」期间应不再调用 `_performLogin`（原逻辑依赖微信 code）。**决策**：当产品关闭微信时，Web 端若仅有 `hasPendingWeChatWebCode` 也不再自动登录；可提示用户改用胖宝号（Toast 一次）并清除 pending code（若存在工具函数）。需在 tasks 中落实避免死循环自动登录。  
   **理由**：避免用户从旧 OAuth 回调页回到登录页后仍尝试微信链。

4. **Android APK 下载与安装**  
   - 依赖：`path_provider`（应用缓存目录）、沿用 `http` 客户端下载（可用 `http.Client.send` + `File.openWrite` 流式，避免大文件内存峰值）。  
   - 保存路径：`getTemporaryDirectory()` 子目录 `apk_updates/` + 确定性文件名（如 `pangbao-update.apk` 或带版本号 sanitize）。下载前可删除旧文件。  
   - 安装：Android 侧使用 **`FileProvider`** 暴露 `content://` URI，`Intent.ACTION_VIEW`，`setDataAndType(uri, "application/vnd.android.package-archive")`，`FLAG_GRANT_READ_URI_PERMISSION`。优先使用 **MethodChannel 薄封装** 或经评估的轻量插件（若引入 `open_filex` 等，须在 `pubspec` 与 ProGuard 中登记）。  
   **理由**：国内 ROM 对 `file://` 安装限制严格；FileProvider 为官方路径。

5. **权限**  
   - `INTERNET`（已有）。  
   - `REQUEST_INSTALL_PACKAGES`（Android O+ 从应用内发起安装包意图时常需；若目标 SDK 限制，降级为跳转系统「安装未知应用」设置）。  
   - 不在公共 Download 目录写文件，避免 `MANAGE_EXTERNAL_STORAGE`。  
   **理由**：降低审核与权限滥用风险。

6. **厂商差异**  
   华为/小米/OPPO/vivo 可能在首次安装时拦截：设计层要求 UI 在 `startActivity` 失败或捕获 `ActivityNotFoundException` 时 Toast 引导用户到系统「允许此来源的应用」设置，不强制区分厂商 API。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 网关 `device_login` 响应结构与微信登录不一致 | 实现前与后端对齐字段；代码中保留与现有 `login` 相同的解析分支与明确错误 Toast。 |
| 目标 SDK 34+ 对安装权限更严 | 使用 `PackageManager.canRequestPackageInstalls()` 检测，未授权时跳转 `Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES` 或 `package installer settings`。 |
| 大 APK 下载中断 | 展示进度；失败允许重试；可选校验 Content-Length。 |
| Web 旧 OAuth 回调残留 | 登录页不再自动 `_performLogin` 于微信 code；必要时清理 sessionStorage 中的 pending code。 |

## Migration Plan

1. 先合并接口与登录 UI，保证胖宝号路径可用。  
2. 再合 Android 下载安装与 Manifest。  
3. 线上观察安装失败率，再考虑是否增加 MD5 校验或断点续传。

## Open Questions

- `device_login` 是否返回 `refreshToken`（与现有刷新链一致）？若无，需在 tasks 中注明 `trySilentRefresh` 行为与产品确认。  
- APK 下载 URL 是否全为 HTTPS；若存在 HTTP cleartext，需在 `network_security_config` 中放行该域名（不推荐全局 cleartext）。
