## Why

华为等应用市场上架审核会卡「未知来源安装包权限」与「未披露/未使用的定位 SDK」。当前 Android 仍走应用内下载 APK + `REQUEST_INSTALL_PACKAGES`，且 `geolocator` 可能残留进包；市场渠道尚未定，不宜依赖商店 deep link。

## What Changes

- **BREAKING（Android 更新）**：取消应用内 APK 下载与安装；更新弹窗引导用户前往官网安装最新版；「去更新」用系统浏览器打开 `https://www.pangbao.cuplay.top/`。
- 从 Android Manifest 移除 `REQUEST_INSTALL_PACKAGES`；拆除/停用 installer MethodChannel 与下载进度安装 UI。
- 版本检查 API / 设置「检查更新」/ 主壳自动检查 **保留**；仅改变 Android 确认后的动作。
- iOS 仍走 App Store；Web 仍刷新引导。
- **发布包剔除 `geolocator`**：pubspec 不依赖；UCG 定位保持 Dart 桩；确认干净 rebuild 后 APK 无该原生 SDK。
- 在 UCG feature flag / 定位桩旁留下「开通 UCG 时恢复 geolocator」清单提醒。

## Capabilities

### New Capabilities

- `android-official-site-update`：Android 更新确认后外链官网的契约（URL、浏览器模式、无装包权限）。

### Modified Capabilities

- `app-versioning`：将「Android 应用内下载并安装」改为官网引导；设置检查更新文案对齐。
- `android-apk-cached-install`：废弃应用内 APK 安装主路径（REMOVED / 改为 MUST NOT）。
- `ucg-location-consent`：发布态定位为未启用桩；不得捆绑 geolocator 进正式包，直至产品明示重开 UCG 定位。

## Impact

- App：`version_prompt.dart`、`apk_update*`、`MainActivity` installer 通道、`AndroidManifest.xml`、`app/README.md`。
- 依赖：`pubspec.yaml` 无 geolocator；`ucg_location.dart` 桩；plugin registrant 需干净再生。
- 上架：有利于华为等审核去掉安装未知应用权限与无用定位 SDK。
- 后续：开通 UCG 广场定位时须恢复 SDK、权限与隐私披露（见 design 清单）。
