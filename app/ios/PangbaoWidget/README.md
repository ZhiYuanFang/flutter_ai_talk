# PangbaoWidget（iOS Widget Extension）

Flutter 侧已通过 `home_widget` 写入 App Group `group.com.fzy.pangbao.widget`，键名 `widgetPayload`。

## Xcode 一次性配置

1. 打开 `app/ios/Runner.xcworkspace`。
2. **File → New → Target → Widget Extension**，Product Name：`PangbaoWidget`，Include Configuration App Intent：否。
3. 删除 Xcode 自动生成的 Swift 文件，将本目录下 `PangbaoWidget.swift`、`Info.plist`、`PangbaoWidget.entitlements` 加入 Extension target。
4. **Runner** 与 **PangbaoWidget** 的 Signing & Capabilities 均添加 App Group：`group.com.fzy.pangbao.widget`（与 `Runner.entitlements` 一致）。
5. Extension 的 `kind` 须为 **`PangbaoWidget`**（与 Flutter `HomeWidgetConstants.iOSWidgetName` 一致）。
6. 真机运行后在桌面添加小/中/大尺寸 widget 验证。

## 数据格式

见 OpenSpec `openspec/changes/home-feed-upcoming-widget/design.md` payload schema。
