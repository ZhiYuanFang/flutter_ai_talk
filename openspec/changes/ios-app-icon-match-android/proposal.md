# Proposal: ios-app-icon-match-android

## Why

当前 iOS 打包产物的 App 图标与 Android 端不一致，导致跨平台品牌识别割裂，并影响测试与发布验收的一致性判断。需要将 iOS 图标资产与 Android 现有项目图标统一，确保同一版本在两端展示一致。

## What Changes

- 明确 iOS 图标来源必须与 Android 现有主图标保持一致（同源素材、同视觉结果）。
- 调整 Flutter 配置与 iOS 图标生成流程，确保打包时输出正确的 iOS 图标集。
- 增加构建前后的校验与文档说明，避免后续发布再次出现图标漂移。
- 更新 iOS 打包清单中与图标相关的操作步骤与注意事项。

## Capabilities

### New Capabilities

- `ios-app-icon-parity`: 规范 iOS 打包产物的图标必须与 Android 项目图标一致，并定义生成与校验要求。

### Modified Capabilities

- （无）

## Impact

- 受影响配置：app/pubspec.yaml（flutter_launcher_icons 配置）
- 受影响资源：app/assets/images/app_icon.png（或其同源图标资产）
- 受影响 iOS 工程资源：app/ios/Runner/Assets.xcassets/AppIcon.appiconset/**
- 受影响文档：docs/ios-github-actions-checklist.md、可能涉及 docs/github-ios-ipa.md
- 受影响流程：iOS GitHub Actions 打包前图标生成/校验步骤
