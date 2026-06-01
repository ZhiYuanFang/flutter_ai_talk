## ADDED Requirements

### Requirement: 版本检测结果提示

The system SHALL compare the running build to a supplied version descriptor (mock in M1) and SHALL surface an update prompt when newer is indicated. 系统必须将当前运行版本与后端或配置提供的版本描述（M1 可为 Mock）比较，当指示存在更高版本时，必须向用户展示更新提示。

#### Scenario: 发现新版本

- **WHEN** 版本检查表明远端版本高于当前构建
- **THEN** 系统必须展示用户可见的更新提示

### Requirement: iOS 经 App Store 更新

The system SHALL on iOS guide users to the App Store listing and SHALL open the App Store URL on acceptance. 在 iOS 上，当按产品规则需要或建议更新时，系统必须引导用户前往 App Store 中本应用的页面，且用户确认后必须打开 App Store URL。

#### Scenario: 用户在 iOS 确认前往商店

- **WHEN** 用户在 iOS 上从更新提示确认前往 App Store
- **THEN** 系统必须打开 **胖宝** 在 App Store 的商品页

### Requirement: Android 应用内下载并安装

The system SHALL on Android download the update package in-app and SHALL initiate OS install using approved mechanisms (permissions/FileProvider as needed in production). 在 Android 上，当按产品规则提供更新时，系统必须在应用体验内下载新安装包，并通过系统允许的方式发起安装（生产构建中按需处理权限与 FileProvider 等）。

#### Scenario: 用户在 Android 完成下载后安装

- **WHEN** 用户接受 Android 更新且下载成功完成
- **THEN** 系统必须触发系统对该已下载包的安装流程

### Requirement: Web 刷新引导

The system SHALL on Web prompt refresh or re-entry when a newer deployment is detected and SHALL NOT attempt APK installation. 在 Web 上，当检测到较新的部署或版本令牌时，系统不得尝试安装 APK；必须提示用户刷新页面或重新进入应用。

#### Scenario: Web 端提示新版本

- **WHEN** Web 客户端检测到已部署的较新版本
- **THEN** 系统必须展示刷新或重新加载应用壳的说明或控件
