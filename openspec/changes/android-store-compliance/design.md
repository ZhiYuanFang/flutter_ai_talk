## Context

Android 更新现为：`version/check` → 弹窗 → 下载 APK 到 cache → FileProvider → `REQUEST_INSTALL_PACKAGES` 调起安装。iOS 已外链 App Store。官网 [https://www.pangbao.cuplay.top/](https://www.pangbao.cuplay.top/) 已提供 Android 下载入口。市场渠道未定，不宜 `market://`。

定位：`geolocator` 工作区已从 pubspec 剔除，`ucg_location.dart` 为桩；需保证 release 扫包无残留。UCG 主壳 flag 仍关。

## Goals / Non-Goals

**Goals:**

- Android 更新确认 → 系统浏览器打开官网常量 URL。
- 正式包无 `REQUEST_INSTALL_PACKAGES`、无应用内装包路径。
- 正式包无 `geolocator` 原生 SDK；定位调用保持安全 no-op。
- 留下「开 UCG 时恢复定位 SDK」的可发现提醒。

**Non-Goals:**

- 不定制各应用市场 deep link（待渠道明确后再议）。
- 不改版本检查协议本身。
- 本期不重开 UCG 广场 / 真实 GPS。
- 不改 iOS / Web 更新路径。

## Decisions

### 1. Android「去更新」只开官网

- **选择**：常量 `kAndroidUpdateWebUrl = 'https://www.pangbao.cuplay.top/'`；`launchUrl(..., LaunchMode.externalApplication)`。
- **理由**：渠道未定；官网已有下载区；审核观感优于未知来源安装。
- **备选**：跳华为/通用 market（拒：渠道未定）。

### 2. 彻底移除应用内装包，而非仅藏 UI

- **选择**：Manifest 删权限；Dart 不再调用 `downloadAndInstallApkFromUrl`；MainActivity installer 通道删除或空实现；进度对话框删除。
- **理由**：审核扫权限声明，藏按钮不够。
- **备选**：保留代码用 flag 关掉（拒：权限仍在 Manifest）。

### 3. `androidApkUrl` 不再驱动 Android 安装

- **选择**：Android CTA 忽略下载 URL；版本检查仍可返回该字段供后台/其它用途，客户端不用于安装。
- **理由**：避免误走旧下载路径。

### 4. geolocator = 去依赖 + Dart 桩（方案 A）

- **选择**：pubspec 无 geolocator；`ucg_location` 保持桩；`flutter pub get` + clean 后确认 registrant 无插件。
- **理由**：flag 关 UCG 不能去原生 SDK；A 是审核最低风险。
- **开 UCG 恢复清单**（须写在 `kUcgHomePagerEnabled` 旁与本 design）：
  1. pubspec 加回 `geolocator`
  2. 还原 `ucg_location` 真实现
  3. Manifest LOCATION + 隐私/用途披露
  4. 扫包确认有意进包

## Risks / Trade-offs

- [用户点更新后需自行在官网下包安装] → 文案写清「请前往官网下载安装最新版」；强制更新仍可禁「稍后」。
- [脏构建仍打进 geolocator] → tasks 含 clean + 扫包验收。
- [FileProvider 误删] → 仅删装包逻辑；视频等共用 Provider 保留。

## Migration Plan

1. 改 `maybeShowVersionPrompt` Android 分支 → 官网。
2. 删权限与 installer / 下载 UI。
3. 收尾 geolocator 剔除与扫包。
4. 注释 + README；开 UCG 清单入 flag。
5. `flutter build apk --release`（本变更触及 `app/android/**`）。

## Open Questions

- 官网是否改为直达带 `#download` 锚点——默认首页即可，锚点可选增强。
