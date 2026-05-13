## Why

产品要求以「胖宝号」（设备号）作为默认登录方式，并暂时关闭微信登录入口；同时 Android 端版本更新需符合国内主流机型习惯：先下载到应用缓存再调起系统安装，而非仅外链浏览器。

## What Changes

- 登录页新增「胖宝号登录」：用户输入 `device_no`，调用网关 `POST /device/app/api/device_login` 完成登录；**默认展示该方式**（首屏焦点与主流程）。
- 保留「微信登录」入口的 UI，但点击时**不得**发起微信授权或网关微信登录；必须提示文案：**「当前功能未开放」**。
- Web 端：胖宝号登录与微信拦截行为与移动端一致（同一套交互与接口约束）；Web 不涉及 APK 安装。
- Android 版本更新：从版本接口的 `download_url`（或等价字段）**下载 APK 至应用缓存目录**，下载完成后通过 **PackageInstaller / Intent.ACTION_VIEW**（配合 `FileProvider`）调起安装；需处理 **REQUEST_INSTALL_PACKAGES**、各厂商「未知来源安装」引导等常见约束。
- iOS 版本更新：维持「跳转 App Store」，不涉及 APK 下载安装。

## Capabilities

### New Capabilities

- `login-device-no`：登录页胖宝号（`device_no`）登录、`/device/app/api/device_login` 联调、微信入口拦截与默认登录方式。
- `android-apk-cached-install`：Android 端应用内下载 APK 至缓存并发起安装，覆盖华为、小米、OPPO、vivo 等常见机型所需权限与路径策略。

### Modified Capabilities

- （无）本变更在独立 change 中定义新能力；与历史 `pangbao-app` 中 app-versioning 文案对齐但不修改已归档 spec。

## Impact

- **Flutter**：`LoginScreen`、`RemoteAuthRepository` / `AuthRepository`、`data/repositories.dart` 抽象、路由与 Toast。
- **依赖**：可能新增 `path_provider`、`permission_handler` 或 `open_filex` / `install_plugin` 等（以 design 为准）；Android `AndroidManifest.xml`、`network_security_config`（若需）、`FileProvider` 与 `xml` 路径。
- **后端契约**：`device_login` 响应体须与现有微信登录一致或可映射为 `accessToken` / `refreshToken` / 可选 `deviceNo`（与现有 `persistTokens`、设备号本地缓存逻辑兼容）。
