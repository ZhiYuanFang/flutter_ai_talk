## Why

[胖宝中国区 App Store 商品页](https://apps.apple.com/cn/app/%E8%83%96%E5%AE%9D/id6774418472) 的名称与描述已是中文，但「信息 → 语言」仍显示 **英语**。该字段来自上传 **IPA 二进制** 所声明的 iOS 本地化，而非 App Store Connect 商品文案；当前 Flutter 默认 iOS 工程仅声明 `en`，CI 的 `prepare_ios_project.sh` 也未写入简体中文。需在现有 iOS 发布 workflow 构建链中声明 `zh-Hans`，使商店页语言标签与 App 实际中文 UI 一致。

## What Changes

- 增强 `app/tool/ci/prepare_ios_project.sh`：写入 `CFBundleDevelopmentRegion`、`CFBundleLocalizations`，并生成 `Runner/zh-Hans.lproj/InfoPlist.strings`（至少含显示名占位，可与 `IOS_APP_DISPLAY_NAME` 对齐）。
- （可选）扩展 `configure_ios_project.rb` 或同脚本：确保 Xcode `knownRegions` 含 `zh-Hans`。
- 更新 `docs/github-ios-ipa.md` / `docs/ios-github-actions-checklist.md`：说明 App Store「语言」字段来自 binary 本地化声明；上传新 build 后才会更新商店展示。
- **不**引入 `fastlane deliver` metadata 同步（商品文案已是中文，非本变更范围）。
- **不**修改 Flutter 运行时 `locale`（已为 `zh_CN`）。

## Capabilities

### New Capabilities

- `ios-app-bundle-localization`：iOS 发布构建须在 IPA 中声明简体中文（`zh-Hans`）本地化，使 App Store 商品页「语言」显示为中文。

### Modified Capabilities

- `app-store-metadata-checklist`：提审清单增补「确认 ASC 处理后的 build 在 App Store 商品页语言为中文（简体中文）」自检项。

## Impact

| 范围 | 路径 / 系统 |
|------|-------------|
| **flutter_ai_talk** | `app/tool/ci/prepare_ios_project.sh`、（可选）`app/tool/ci/configure_ios_project.rb` |
| **文档** | `docs/github-ios-ipa.md`、`docs/ios-github-actions-checklist.md` |
| **CI** | `.github/workflows/ios-build-core.yml`（仅当需传新 env；预期无 workflow 结构变更） |
| **不受影响** | App 内 UI 文案、ASC 商品描述、TestFlight 上传逻辑、Android 构建 |
