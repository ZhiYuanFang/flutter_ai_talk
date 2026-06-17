## ADDED Requirements

### Requirement: iOS 发布构建 MUST 在 IPA 中声明简体中文本地化

The iOS release build pipeline MUST declare Simplified Chinese (`zh-Hans`) in the app bundle so App Store product pages show Chinese as a supported language.

GitHub Actions iOS 发布构建（`app/tool/ci/prepare_ios_project.sh` 执行路径）必须在写入 `Info.plist` 时：

- 设置 `CFBundleDevelopmentRegion` 为 `zh-Hans`；
- 设置 `CFBundleLocalizations` 包含 `zh-Hans`（v1 仅简体中文，不得仅保留默认 `en`）；
- 创建 `ios/Runner/zh-Hans.lproj/InfoPlist.strings`，且 MUST 非空；`CFBundleDisplayName` MUST 使用 `IOS_APP_DISPLAY_NAME`（若已设置且非空），否则 MUST 默认为 `胖宝`。

#### Scenario: CI 执行 prepare 脚本后 plist 含中文区域

- **WHEN** `prepare_ios_project.sh` 在 iOS 工程已存在时完成执行
- **THEN** `ios/Runner/Info.plist` MUST 含 `CFBundleDevelopmentRegion` = `zh-Hans`
- **AND** `CFBundleLocalizations` MUST 包含 `zh-Hans`

#### Scenario: CI 生成 zh-Hans 资源目录

- **WHEN** `prepare_ios_project.sh` 完成执行
- **THEN** MUST 存在 `ios/Runner/zh-Hans.lproj/InfoPlist.strings`
- **AND** 该文件 MUST 含 `CFBundleDisplayName` 键且值为非空中文字符串

#### Scenario: 上传新 build 后 App Store 语言标签为中文

- **WHEN** 使用声明 `zh-Hans` 的 IPA 经 `testflight` 或 `appstore` workflow 上传至 App Store Connect 且 build 处理完成
- **THEN** App Store Connect 中该 build 的 Included Localizations MUST 包含 Chinese (Simplified) 或等效项
- **AND** 中国区 App Store 商品页「语言」字段 MUST 显示中文（简体中文）而非仅「英语」
