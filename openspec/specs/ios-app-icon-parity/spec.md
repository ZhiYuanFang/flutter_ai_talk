# iOS App 图标与 Android 一致化（ios-app-icon-parity）

## ADDED Requirements

### Requirement: iOS 图标必须与 Android 同源
The iOS app icon source **MUST** be the same master asset used by Android.

iOS 打包所使用的图标源文件必须与 Android 主图标资产同源，项目不得为 iOS 维护独立且不一致的图标主源。默认主源为 `app/assets/images/app_icon.png`，若后续调整路径，必须同步更新 Android 与 iOS 生成配置，确保最终视觉结果一致。

#### Scenario: 读取图标源配置
- **WHEN** 开发者检查 `app/pubspec.yaml` 中的图标配置
- **THEN** iOS 与 Android 图标生成输入必须指向同一个主图标源文件

### Requirement: iOS 图标集必须由统一生成流程产出
The iOS app icon set **SHALL** be generated through a single managed pipeline rather than manual edits.

项目必须通过统一图标生成流程（`flutter_launcher_icons`）产出 iOS `AppIcon.appiconset`，不得将手工改动 `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` 作为长期维护方式。生成后文件需纳入版本控制，保证本地与 CI 结果可复现。

#### Scenario: 生成 iOS 图标集
- **WHEN** 运行既定的图标生成流程
- **THEN** `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` 必须包含完整且可用于打包的图标文件与 `Contents.json`

### Requirement: iOS 打包前必须执行图标一致性校验
The iOS packaging workflow **MUST** validate icon parity before producing IPA artifacts.

iOS 打包流程在产出 IPA 前必须执行图标一致性校验。校验至少应覆盖：主图标源存在、iOS 图标集存在且完整、配置未偏离同源策略。若校验失败，流程必须中止并输出可执行的修复指引。

#### Scenario: 图标一致性校验通过
- **WHEN** CI 或本地打包前执行图标一致性检查且所有条件满足
- **THEN** 流程继续执行归档与导出步骤

#### Scenario: 图标一致性校验失败
- **WHEN** 图标源缺失、配置不一致或 iOS 图标集不完整
- **THEN** 流程必须失败并提示重新生成图标及同步配置的修复步骤
