## 1. 数据层

- [x] 1.1 调整 `RemoteVersionRepository.checkForUpdate`：仅在 `needUpdate=false` 时返回 `null`；网络/API 错误 MUST rethrow，不再将 `ApiBusinessException` 吞为 `null`

## 2. 设置中心 UI

- [x] 2.1 在 `SettingsScreen` 增加 `_currentVersion`、`_checking` 状态；`initState` 调用 `readPackageVersion()` 填充版本号
- [x] 2.2 在「隐私政策」tile 下方新增「检查更新」`_buildGlassTile`：subtitle 为 `当前版本 {version}`，对游客与已登录用户均可见
- [x] 2.3 实现 `_onCheckUpdateTap`：防重复点击、loading 态、`checkForUpdate` → 有更新调用 `maybeShowVersionPrompt`、无更新 `showApiToast('已是最新版本')`、失败 `showApiToast('检查失败，请稍后重试')`；全程 `mounted` guard

## 3. 验收

- [x] 3.1 手动验证：设置页展示版本号；点击后 loading；mock/真实接口下分别验证「有更新弹窗」「已最新 Toast」「失败 Toast」
- [x] 3.2 确认主页登录后被动版本检查行为未回归（有更新仍弹窗、失败仍静默）
