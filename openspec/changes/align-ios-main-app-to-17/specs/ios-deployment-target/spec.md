## MODIFIED Requirements

### Requirement: 主 App 最低部署版本为 15

iOS Runner 工程的 `IPHONEOS_DEPLOYMENT_TARGET` MUST 默认为 **17.0**（或通过 `IOS_DEPLOYMENT_TARGET` 设置为不低于 17.0 的值）。主 App MUST NOT 以 12.x、13.0、15.0 或「仅满足 FlutterFramework / mobile_scanner 地板」作为仓库默认基线。

#### Scenario: 提交中的 Runner 工程

- **WHEN** 检查仓库内 `app/ios/Runner.xcodeproj` 各相关 build configuration
- **THEN** `IPHONEOS_DEPLOYMENT_TARGET` 均为 17.0（或显式配置的 ≥17.0 覆盖值）

#### Scenario: 拒绝降级到 13 或 15 作为默认

- **WHEN** 因 SPM 报错或 CocoaPods（如 `mobile_scanner` 要求 15.5）而调整部署版本
- **THEN** 默认对齐结果为 17.0（或更高覆盖），而不是仅提升到 13.0 或 15.x

### Requirement: CocoaPods 与主 App 部署版本同步

`prepare_ios_project.sh`（或等价入口）MUST 将 `ios/Podfile` 的 `platform :ios` 设为与 `IOS_DEPLOYMENT_TARGET` 默认一致的 **17.0**（可覆盖，不得默认低于 17），并 MUST 在 `post_install` 中将各 Pod target 的 `IPHONEOS_DEPLOYMENT_TARGET` 同步为同一值。

#### Scenario: prepare 后的 Podfile

- **WHEN** 执行 `prepare_ios_project.sh` 且未设置更低的覆盖值
- **THEN** Podfile 含 `platform :ios, '17.0'`（或等价覆盖 ≥17.0），且 post_install 会写入对应的 `IPHONEOS_DEPLOYMENT_TARGET`

#### Scenario: mobile_scanner 可被 CocoaPods 解析

- **WHEN** 依赖含 `mobile_scanner` 6.x（podspec 平台 ≥15.5）且已执行 prepare + `pod install`
- **THEN** MUST NOT 因主 App / Podfile 平台低于该 pod 要求而失败

### Requirement: AppFrameworkInfo 声明 MinimumOSVersion 15

仓库内 `ios/Flutter/AppFrameworkInfo.plist` MUST 包含 `MinimumOSVersion` 且默认值为 **17.0**（或与 `IOS_DEPLOYMENT_TARGET` 一致且不低于 17）。`prepare_ios_project.sh` MUST 幂等保证该键存在，以免 Flutter 生成 SPM 包时落回 12.0。

#### Scenario: plist 含 17.0

- **WHEN** 检查提交的 `AppFrameworkInfo.plist` 或执行 prepare 之后
- **THEN** 存在 `MinimumOSVersion` 且值为 17.0（或 ≥17 的覆盖值）

### Requirement: ephemeral SPM Package.swift 平台不低于主 App 基线

在启用 Swift Package Manager 的构建中，于生成 ephemeral Packages 之后、执行 **Xcode archive 正前**，构建流程 MUST 将消费方 `Package.swift`（含 `FlutterGeneratedPluginSwiftPackage`、以及 `$PUB_CACHE` / `package_config` 中依赖 `FlutterFramework` 的插件如 `photo_manager`）中低于主 App 基线（默认 17.0）的 `.iOS("…")` 提升到该基线。`FlutterFramework` 的 platforms MUST 仅保证不低于 13.0，MUST NOT 被抬到主 App 17 作为产品要求。CI MUST 通过直调 `xcodebuild archive`（而非依赖 PATH 包装的裸 `flutter build ipa`）保证对齐不被绕过。

#### Scenario: CI 消除 FlutterFramework 与 SPM 12.0 冲突

- **WHEN** 完成 config-only、ensure Widget、align 后执行 `xcodebuild archive`
- **THEN** 不得再出现「FlutterFramework 要求 13.0，但 this target supports 12.0」的 Target Integrity 失败

#### Scenario: FlutterFramework 不被抬到 17

- **WHEN** align 处理 `FlutterFramework/Package.swift` 且其声明为 13.0
- **THEN** 保持 13.0（或 ≥13），不得改写成 17.0

#### Scenario: 已高于基线的声明不被降低

- **WHEN** 某消费方 `Package.swift` 已声明 `.iOS("17.0")`（或其它 ≥ 基线的值）
- **THEN** 对齐脚本 MUST NOT 将其降低到低于当前主 App 基线的值

### Requirement: Widget Extension 保持 17 且不被主 App 覆盖

PangbaoWidget Extension 的 `IPHONEOS_DEPLOYMENT_TARGET` MUST 默认为 **17.0**（或 `IOS_WIDGET_DEPLOYMENT_TARGET` 覆盖）。配置签名或主 App 部署版本的脚本 MUST NOT 将 Widget 的部署版本改写为低于 17.0 的值（包括不得因历史「主 App=15」逻辑把 Widget 写成 15.0）。

#### Scenario: 签名配置后 Widget 仍为 17

- **WHEN** 运行 `configure_ios_project.rb`（或等价签名配置）且存在 PangbaoWidget target
- **THEN** Widget 的 `IPHONEOS_DEPLOYMENT_TARGET` 仍为 17.0（或 Widget 专用覆盖值），Runner 为 17.0（或主 App ≥17 覆盖值）

### Requirement: 厂商 SDK 最低版本不充当 App 基线

vendored `WechatOpenSDK` 的 podspec / `MinimumOSVersion` 为 12.0 时，系统 MUST 允许其保持不变；App / Pods / SPM 对齐基线仍以 **17.0** 为准。

#### Scenario: 不改 WechatOpenSDK 的 12.0

- **WHEN** 对齐主 App / Pods / SPM 到 17.0
- **THEN** 不要求修改 WechatOpenSDK 二进制或 podspec 中的 12.0 最低版本声明
