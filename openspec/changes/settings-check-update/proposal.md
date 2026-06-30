## Why

当前版本检查仅在登录用户进入主页后被动触发，未登录用户与希望主动确认版本的用户缺少入口。设置中心是用户查找应用信息的自然位置，应在该处提供「检查更新」并展示当前版本，便于手动触发既有 `version/check` 流程。

## What Changes

- 在设置中心（`/settings`）新增「检查更新」玻璃 tile，subtitle 展示当前应用版本（`package_info` 的 `version` 字段）。
- 用户点击 tile 时调用既有 `VersionRepository.checkForUpdate`（`GET /device/app/api/version/check`，无鉴权）。
- 若接口表明需更新，复用既有 `maybeShowVersionPrompt`（iOS App Store / Android 应用内下载 / Web 刷新引导）。
- 若接口表明无需更新，向用户展示「已是最新版本」轻提示（`AppToast`）。
- 检查进行中须防重复点击并展示 loading 态；网络或未知错误须展示「检查失败，请稍后重试」类轻提示，不得与「已是最新」混淆。
- 该入口对游客与已登录用户均可见（与 `/settings` 路由门禁一致，不要求登录）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `app-versioning`：增补设置中心手动检查更新、展示当前版本、无更新与失败时的用户反馈要求。

## Impact

- **UI**：`app/lib/ui/settings_screen.dart`（或抽取小型 tile 组件）；复用 `app/lib/ui/version_prompt.dart`。
- **数据层**：复用 `RemoteVersionRepository`、`readPackageVersion`；可能微调 repository 以区分「无更新」与「请求失败」（若 design 采用该方案）。
- **OpenSpec**：`app-versioning` capability delta。
- **无**新 HTTP 接口、无 Android R8 / WebSocket 架构变更。
