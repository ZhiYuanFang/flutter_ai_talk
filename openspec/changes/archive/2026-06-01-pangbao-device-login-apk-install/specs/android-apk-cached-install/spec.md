## ADDED Requirements

### Requirement: 版本接口与安装数据流

The system SHALL use the version check API’s `download_url` (and snake_case alias if present) as the sole source URL for Android in-app APK retrieval in the update flow described in this capability. Android 应用内更新必须使用版本检查接口返回的 **`download_url`**（及若存在的 **`downloadUrl`** 等别名解析结果）作为 APK 下载源，不得硬编码商店地址作为该流程的主 URL。

#### Scenario: 接口返回需更新且含下载地址

- **WHEN** 版本检查表明需更新且 `download_url` 非空
- **THEN** Android 更新流程必须使用该 URL 作为下载起点

### Requirement: 主流 ROM 兼容性约束

The system SHALL implement APK download and install using APIs compatible with common vendor Android devices (Huawei, Xiaomi, OPPO, vivo, etc.) without requiring root. 实现必须兼容市面常见 Android 机型（含华为、小米、OPPO、vivo 等）：使用应用私有目录存储 APK、`FileProvider` 共享 URI、按目标 SDK 处理安装权限；不得依赖 root 或私有未文档化厂商 API 作为必要条件。

#### Scenario: 在常见国内 ROM 上完成安装

- **WHEN** 用户在常见国内 ROM 上完成下载且已授予安装权限
- **THEN** 系统必须能调起系统安装器处理该 APK

### Requirement: iOS 与 Web 不得走 APK 安装路径

The system SHALL NOT run the Android APK download-and-install flow on iOS or Web. iOS 与 Web 平台不得执行 Android APK 下载或安装逻辑；iOS 必须保持跳转 App Store；Web 必须保持刷新或重新进入引导。

#### Scenario: 非 Android 平台打开更新提示

- **WHEN** 运行平台为 iOS 或 Web
- **THEN** 系统不得下载 `.apk` 文件或调用 Android PackageInstaller 相关代码路径
