# PangbaoWidget（iOS Widget Extension）

Flutter 侧已通过 `home_widget` 写入 App Group `group.com.fzy.pangbao.widget`，键名 `widgetPayload`。

## 无 Mac / CI 打包（推荐）

仓库 **无需本地 Xcode**。GitHub Actions 会在每次 iOS 构建时：

1. 运行 `app/tool/ci/ensure_pangbao_widget_target.rb` 自动创建 Extension target 并嵌入 Runner
2. 运行 `app/tool/ci/ensure_pangbao_widget_home_widget_pod.rb` 写入 Podfile 的 `PangbaoWidget` → `home_widget`，再 `pod install`
3. 使用 **两份**描述文件签名（主 App + Widget Extension）
4. `flutter build ipa` 产出含小组件的 IPA

### Apple Developer 网页配置（一次性）

| 步骤 | 操作 |
|------|------|
| 1 | **App Groups** → 新建 `group.com.fzy.pangbao.widget` |
| 2 | App ID `com.fzy.pangbao` → 启用 **App Groups** → 勾选上述 group → **重新生成** `pangbao-appstore` 等主 App 描述文件 |
| 3 | 新建 App ID `com.fzy.pangbao.widget` → 启用 **App Groups**（同一 group） |
| 4 | **Profiles** → 为 Extension App ID 新建 App Store 描述文件（如 `pangbao-widget-appstore`） |
| 5 | 更新 GitHub Secrets（见下） |

### GitHub Secrets

| Secret | 说明 |
|--------|------|
| `IOS_MOBILEPROVISION_APPSTORE_BASE64` | 主 App App Store 描述文件（**须含 App Groups**） |
| `IOS_MOBILEPROVISION_WIDGET_APPSTORE_BASE64` | Widget Extension App Store 描述文件 |
| `IOS_WIDGET_BUNDLE_ID` | 可选；默认 `com.fzy.pangbao.widget`（即 `{IOS_BUNDLE_ID}.widget`） |

Ad Hoc / Development 分发同理：`IOS_MOBILEPROVISION_WIDGET_ADHOC_BASE64` 等。

CI 会在构建前校验描述文件 Bundle ID、Team ID、App Group 与过期时间。详见 [docs/github-ios-ipa.md](../../../docs/github-ios-ipa.md)「桌面小组件 / App Groups」章节。

## 本地 Xcode（可选）

若你有 Mac，也可手动：

1. 打开 `app/ios/Runner.xcworkspace`
2. **File → New → Target → Widget Extension**（Product Name：`PangbaoWidget`）
3. 用本目录下 `PangbaoWidget.swift`、`Info.plist`、`PangbaoWidget.entitlements`、`WidgetBackgroundIntent.swift` 替换/加入自动生成文件
4. Runner 与 PangbaoWidget 均添加 App Group：`group.com.fzy.pangbao.widget`
5. Extension 的 `kind` 须为 **`PangbaoWidget`**（与 `HomeWidgetConstants.iOSWidgetName` 一致）
6. **交互「跳过」**：`WidgetBackgroundIntent.swift` 须同时加入 **Runner** 与 **PangbaoWidget** target；Extension 须能 `import home_widget`：
   - **CocoaPods（本仓 CI）**：`ensure_pangbao_widget_home_widget_pod.rb` 为 `PangbaoWidget` 声明 `pod 'home_widget'` 后再次 `pod install`
   - **SPM**：Extension Frameworks 链接 `FlutterGeneratedPluginSwiftPackage`（可选补充）
7. Runner `AppDelegate` 须保留 iOS 17+ `HomeWidgetBackgroundWorker.setPluginRegistrantCallback`（勿删）

## 交互「跳过」前置（Android / iOS）

点小组件「跳过」走 `home_widget` 后台回调，**不是**整卡打开 App。缺任一项会表现为按钮无反应：

| 平台 | 必需要件 |
|------|----------|
| Android | App `AndroidManifest` 声明 `HomeWidgetBackgroundReceiver` + `HomeWidgetBackgroundService`（插件 library Manifest **不**自带） |
| Android | 至少冷启一次 App，使 `HomeWidget.registerInteractivityCallback` 写入 callbackHandle |
| Android | 改 Manifest / Renderer 后须**完整重装**，勿只 hot reload |
| iOS 17+ | 上表第 6–7 步（含 Podfile Extension→home_widget）；`ForegroundContinuableIntent` 便于 App 挂起时仍进 Dart |
| iOS &lt;17 | 不展示「跳过」按钮，整卡仍可打开 App |

相关 change：`openspec/changes/widget-hero-skip-next`、`openspec/changes/fix-widget-hero-skip-interactivity`。

## 数据格式

见 OpenSpec `openspec/changes/home-feed-upcoming-widget/design.md` payload schema。
