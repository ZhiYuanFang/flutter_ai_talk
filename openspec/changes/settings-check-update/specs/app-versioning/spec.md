## ADDED Requirements

### Requirement: 设置中心展示当前版本

The settings screen SHALL display the running application version and SHALL provide a manual "check for update" entry visible to both guest and signed-in users. 设置中心（`/settings`）MUST 提供「检查更新」入口，并在该入口的副标题或等价位置展示当前运行版本（`package_info` 的 `version` 字段）；该入口 MUST 对游客与已登录用户均可见，且 MUST NOT 要求登录。

#### Scenario: 进入设置页看到版本

- **WHEN** 用户打开设置中心且 `readPackageVersion` 已成功
- **THEN** 「检查更新」入口 MUST 展示当前版本号（如 `2.0.3`）

### Requirement: 设置中心手动检查更新

The system SHALL on user tap of the settings "check for update" entry invoke the existing version check API with the current version and SHALL reuse the existing update prompt flow when an update is indicated. 用户点击「检查更新」时，系统 MUST 以当前版本调用既有 `GET /device/app/api/version/check`（或等价 `VersionRepository.checkForUpdate`）；当接口表明需更新时，MUST 复用既有 `maybeShowVersionPrompt` 流程（含 iOS App Store、Android 应用内下载、Web 刷新引导，与 `app-versioning` 基线一致）。

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
