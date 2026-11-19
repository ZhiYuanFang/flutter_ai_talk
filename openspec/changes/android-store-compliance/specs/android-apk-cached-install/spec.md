## ADDED Requirements

### Requirement: Version-update UX MUST NOT use cached APK install

The client MUST NOT use the version-check `download_url` / `androidApkUrl` as an in-app APK download source for the user-facing update flow. Android update confirmation MUST follow `android-official-site-update` (open the official site) instead of caching an APK under `apk_updates/` and installing via FileProvider. 面向用户的更新流程 MUST NOT 再用版本接口下载 URL 做应用内 APK 缓存安装；MUST 走官网外链。

#### Scenario: Update prompt does not start APK cache download

- **WHEN** 用户在 Android 确认更新
- **THEN** 客户端 MUST NOT 将 APK 下载到 `apk_updates/`（或等价缓存）并调起安装器

## REMOVED Requirements

### Requirement: 版本接口与安装数据流

**Reason**: 上架合规取消应用内装包；Android 改官网引导。
**Migration**: 更新确认改开 `https://www.pangbao.cuplay.top/`；接口 `download_url` 可保留但 MUST NOT 驱动装包 UI。

### Requirement: 主流 ROM 兼容性约束

**Reason**: 不再实现应用内 APK 安装，无需 ROM 装包兼容约束。
**Migration**: 无；官网下载由用户系统浏览器/系统安装器处理。

### Requirement: iOS 与 Web 不得走 APK 安装路径

**Reason**: 全平台更新 UX 已不再含 Android APK 安装路径；该否定式需求并入官网更新能力。
**Migration**: 继续保证 iOS→App Store、Web→刷新；Android→官网。
