## ADDED Requirements

### Requirement: 胖宝号默认登录

The system SHALL present device-number (“胖宝号”) login as the primary and default login path on the login screen and SHALL submit the trimmed value as `device_no` to `POST /device/app/api/device_login`. 登录页必须将「胖宝号登录」作为主路径展示（含输入框与主操作按钮），用户提交前必须对输入做 trim；必须调用网关 `POST /device/app/api/device_login`，JSON 请求体字段名为 **`device_no`**，值为用户输入的胖宝号。

#### Scenario: 用户使用胖宝号登录成功

- **WHEN** 用户输入非空胖宝号并点击主登录按钮且网关返回成功信封
- **THEN** 系统必须持久化 access/refresh token（与现有会话模型一致），按需写入本地 `deviceNo`，并进入应用主流程（与现有登录成功导航一致）

#### Scenario: 网关业务失败

- **WHEN** 网关返回业务错误（如 `code != 0`）
- **THEN** 系统必须向用户展示服务端 `message`（或等价 Toast），且不得错误地标记为已登录

### Requirement: 微信登录入口未开放提示

The system SHALL keep a visible WeChat login entry but SHALL NOT initiate WeChat authorization, web OAuth redirect, or WeChat gateway login when the user activates that entry; it SHALL only notify with the exact text: `当前功能未开放`. 登录页可保留「微信登录」控件，但用户点击时必须仅提示固定文案「当前功能未开放」，不得调用 fluwx、不得跳转微信网页授权、不得请求 `POST /device/app/api/login`。

#### Scenario: 用户点击微信登录

- **WHEN** 用户点击微信登录按钮
- **THEN** 系统必须展示「当前功能未开放」且不得发起任何微信相关网络或 SDK 流程

### Requirement: Web 登录页不与微信自动登录耦合

The system SHALL NOT auto-complete login using a pending WeChat web OAuth code while WeChat login is disabled for users. 在关闭微信登录能力期间，登录页不得因 sessionStorage 等处的待处理微信 code 而自动调用原微信登录成功路径；若检测到残留待处理 code，应提示用户使用胖宝号或静默忽略（具体实现以 tasks 为准），且不得进入已登录态。

#### Scenario: Web 从旧回调返回带 code

- **WHEN** Web 端存在历史 OAuth 回调写入的待处理微信 code
- **THEN** 系统不得自动完成微信网关登录；用户仅能通过胖宝号登录进入应用

### Requirement: Android APK 下载至应用缓存

The system SHALL on Android download the APK from the version API `download_url` (or equivalent) into an app-writable cache or temporary directory before install and SHALL NOT rely on external-browser download as the sole install path for the in-app update flow. 在 Android 上，应用内更新流程必须先将 APK 从接口提供的 HTTPS（或约定）URL **下载到应用私有缓存/临时目录**（不得依赖用户手动从浏览器下载作为唯一路径），下载完成后再进入安装步骤。

#### Scenario: 用户确认 Android 更新且 URL 合法

- **WHEN** 用户在更新对话框确认更新且 `download_url` 为有效 http(s) 地址
- **THEN** 系统必须发起下载并在本地生成可读的 APK 文件供后续安装步骤使用

#### Scenario: 下载失败或磁盘不足

- **WHEN** 下载中断或写入失败
- **THEN** 系统必须向用户展示失败原因或通用错误提示，并允许用户重试（若 UI 提供重试）

### Requirement: Android 调起系统安装

The system SHALL initiate installation via Android-supported mechanisms (e.g. `FileProvider` + `ACTION_VIEW` with grant URI permission) and SHALL declare required manifest entries for target SDK. Android 安装步骤必须通过系统支持的 `content://` URI（如 **FileProvider**）与 **`Intent.ACTION_VIEW`**（类型 `application/vnd.android.package-archive`）等方式调起 **PackageInstaller** 流程，并在 Manifest 中声明 **FileProvider** 与安装相关权限（含按需的 **REQUEST_INSTALL_PACKAGES** 或跳转设置授权）。

#### Scenario: 下载完成后发起安装

- **WHEN** APK 文件已完整写入应用缓存且系统允许本应用发起安装
- **THEN** 系统必须调起系统安装界面

#### Scenario: 系统拒绝安装权限

- **WHEN** 系统策略禁止当前应用安装未知来源包或用户未授权
- **THEN** 系统必须提示用户前往系统设置开启相应权限或「允许此来源」后重试，且不得崩溃
