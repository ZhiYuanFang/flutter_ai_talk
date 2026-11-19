## MODIFIED Requirements

### Requirement: Android 应用内下载并安装

The system SHALL on Android guide users to install the latest build from the official website and SHALL open `https://www.pangbao.cuplay.top/` in an external browser when the user confirms the update prompt. The system MUST NOT download the update package in-app and MUST NOT initiate OS APK install via FileProvider / PackageInstaller as part of the version-update UX. 在 Android 上，当按产品规则提供更新时，系统 MUST 引导用户前往官网安装最新版，用户确认后 MUST 用系统浏览器打开官网；MUST NOT 应用内下载安装包，MUST NOT 经 FileProvider/系统安装器装包。

#### Scenario: 用户在 Android 确认去更新

- **WHEN** 用户接受 Android 更新提示
- **THEN** 系统 MUST 打开官网 `https://www.pangbao.cuplay.top/`
- **AND** MUST NOT 触发应用内 APK 下载或安装流程

### Requirement: 设置中心手动检查更新

The system SHALL on user tap of the settings "check for update" entry invoke the existing version check API with the current version and SHALL reuse the existing update prompt flow when an update is indicated. 用户点击「检查更新」时，系统 MUST 以当前版本调用既有 `GET /device/app/api/version/check`（或等价 `VersionRepository.checkForUpdate`）；当接口表明需更新时，MUST 复用既有 `maybeShowVersionPrompt` 流程（含 iOS App Store、**Android 官网引导**、Web 刷新引导）。

#### Scenario: 手动检查发现新版本

- **WHEN** 用户在设置中心点击「检查更新」且接口返回 `needUpdate=true`（或等价语义）
- **THEN** 系统 MUST 展示与主页被动检查相同的更新提示 UI

#### Scenario: 手动检查已是最新

- **WHEN** 用户在设置中心点击「检查更新」且接口成功返回无需更新（`needUpdate=false` 或等价语义）
- **THEN** 系统 MUST 向用户展示「已是最新版本」类轻提示（如 `AppToast`），且 MUST NOT 展示更新弹窗

#### Scenario: 手动检查进行中防重复

- **WHEN** 版本检查请求尚未完成
- **THEN** 系统 MUST 防止重复发起检查，并 MUST 展示进行中的 loading 反馈

#### Scenario: 手动检查失败

- **WHEN** 用户在设置中心点击「检查更新」且版本检查请求失败（网络错误或 API 业务/HTTP 错误）
- **THEN** 系统 MUST 展示「检查失败，请稍后重试」类轻提示，且 MUST NOT 展示「已是最新版本」
