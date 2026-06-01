# Tasks: ios-app-icon-match-android

## 1. 图标源与配置对齐

- [x] 1.1 确认 Android 当前主图标源文件路径与实际使用资产一致（默认 `app/assets/images/app_icon.png`）
- [x] 1.2 更新 `app/pubspec.yaml` 的 `flutter_launcher_icons` 配置，确保 iOS 与 Android 指向同一图标源
- [x] 1.3 校验图标源规格（分辨率、透明边距、格式）满足 iOS 生成与展示要求

## 2. iOS 图标集生成与仓库落盘

- [x] 2.1 执行统一图标生成流程（`flutter_launcher_icons`）生成 iOS `AppIcon.appiconset`
- [x] 2.2 核对 `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` 关键文件与 `Contents.json` 完整性
- [x] 2.3 提交生成后的 iOS 图标集文件，移除或覆盖历史不一致图标资源

## 3. CI 打包前一致性校验

- [x] 3.1 在 iOS 打包流程中增加图标一致性检查（主源存在、配置同源、AppIcon 集完整）
- [x] 3.2 当校验失败时使流程失败，并输出明确修复指引（重新生成图标、同步配置）
- [x] 3.3 在 CI 日志中保留图标检查结果，便于问题追踪

## 4. 文档与回归验证

- [x] 4.1 更新 iOS 发布清单文档，补充图标一致性步骤与注意事项
- [ ] 4.2 以 `ipa_only` 模式执行一次 iOS 打包并验证安装后图标与 Android 一致
- [ ] 4.3 以 `testflight_internal_only` 模式执行一次上传并验证 TestFlight 安装图标一致
