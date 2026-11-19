## ADDED Requirements

### Requirement: Android update confirm MUST open the official site in an external browser

When the user confirms an Android in-app update prompt (including forced update), the client MUST open the official site URL `https://www.pangbao.cuplay.top/` (or the single documented constant equivalent) using the system browser / external application launch mode. The client MUST NOT download an APK in-app and MUST NOT initiate PackageInstaller / FileProvider APK install as part of this update confirmation. 用户确认 Android 更新时，客户端 MUST 用系统浏览器打开官网 `https://www.pangbao.cuplay.top/`；MUST NOT 应用内下载 APK，MUST NOT 调起安装未知应用装包流程。

#### Scenario: Tap 去更新 opens official site

- **WHEN** 用户在 Android 更新弹窗点击「去更新」（或等价确认文案）
- **THEN** 客户端 MUST 以外部应用方式打开 `https://www.pangbao.cuplay.top/`
- **AND** MUST NOT 开始应用内 APK 下载

#### Scenario: Force update still opens site only

- **WHEN** 更新为强制更新且用户确认前往更新
- **THEN** 客户端 MUST 仍仅打开官网
- **AND** MUST NOT 因强制更新而恢复应用内装包

### Requirement: Android release MUST NOT declare REQUEST_INSTALL_PACKAGES for updates

The Android application Manifest used for store release MUST NOT declare `android.permission.REQUEST_INSTALL_PACKAGES` for the purpose of in-app updates. Any installer MethodChannel / APK cache install path tied to version updates MUST be removed or permanently disabled so it cannot be invoked from the update UI. 上架用 Manifest MUST NOT 为应用内更新声明 `REQUEST_INSTALL_PACKAGES`；更新相关安装通道 MUST 拆除或永久不可从更新 UI 调用。

#### Scenario: Manifest has no install-packages permission

- **WHEN** 审查正式包 AndroidManifest
- **THEN** MUST NOT 出现为更新保留的 `REQUEST_INSTALL_PACKAGES` 声明
