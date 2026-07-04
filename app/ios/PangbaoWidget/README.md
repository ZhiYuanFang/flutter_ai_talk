# PangbaoWidget（iOS Widget Extension）

Flutter 侧已通过 `home_widget` 写入 App Group `group.com.fzy.pangbao.widget`，键名 `widgetPayload`。

## 无 Mac / CI 打包（推荐）

仓库 **无需本地 Xcode**。GitHub Actions 会在每次 iOS 构建时：

1. 运行 `app/tool/ci/ensure_pangbao_widget_target.rb` 自动创建 Extension target 并嵌入 Runner
2. 使用 **两份**描述文件签名（主 App + Widget Extension）
3. `flutter build ipa` 产出含小组件的 IPA

### Apple Developer 网页配置（一次性）

| 步骤 | 操作 |
|------|------|
| 1 | **App Groups** → 新建 `group.com.fzy.pangbao.widget` |
| 2 | App ID `com.fzy.pangbaoApp` → 启用 **App Groups** → 勾选上述 group → **重新生成** `pangbao-appstore` 等主 App 描述文件 |
| 3 | 新建 App ID `com.fzy.pangbaoApp.PangbaoWidget` → 启用 **App Groups**（同一 group） |
| 4 | **Profiles** → 为 Extension App ID 新建 App Store 描述文件（如 `pangbao-widget-appstore`） |
| 5 | 更新 GitHub Secrets（见下） |

### GitHub Secrets

| Secret | 说明 |
|--------|------|
| `IOS_MOBILEPROVISION_APPSTORE_BASE64` | 主 App App Store 描述文件（**须含 App Groups**） |
| `IOS_MOBILEPROVISION_WIDGET_APPSTORE_BASE64` | Widget Extension App Store 描述文件 |
| `IOS_WIDGET_BUNDLE_ID` | 可选；默认 `com.fzy.pangbaoApp.PangbaoWidget` |

Ad Hoc / Development 分发同理：`IOS_MOBILEPROVISION_WIDGET_ADHOC_BASE64` 等。

CI 会在构建前校验描述文件 Bundle ID、Team ID、App Group 与过期时间。详见 [docs/github-ios-ipa.md](../../../docs/github-ios-ipa.md)「桌面小组件 / App Groups」章节。

## 本地 Xcode（可选）

若你有 Mac，也可手动：

1. 打开 `app/ios/Runner.xcworkspace`
2. **File → New → Target → Widget Extension**（Product Name：`PangbaoWidget`）
3. 用本目录下 `PangbaoWidget.swift`、`Info.plist`、`PangbaoWidget.entitlements` 替换自动生成文件
4. Runner 与 PangbaoWidget 均添加 App Group：`group.com.fzy.pangbao.widget`
5. Extension 的 `kind` 须为 **`PangbaoWidget`**（与 `HomeWidgetConstants.iOSWidgetName` 一致）

## 数据格式

见 OpenSpec `openspec/changes/home-feed-upcoming-widget/design.md` payload schema。
