## Why

CI 在 `pod install` 时因 `mobile_scanner` 6.x 要求 **iOS 15.5+**，而主 App / Podfile 仍默认 **15.0** 失败。产品侧 Live Activity / Widget Extension 已固定 **17.0**，主 App 继续留在 15 只会反复被依赖地板抬高；将主 App 默认部署版本对齐 **17.0**，一次消掉 CocoaPods 冲突并与 Widget/LA 安装门槛一致。

## What Changes

- **BREAKING**：主 App（Runner）默认 `IPHONEOS_DEPLOYMENT_TARGET` / Podfile `platform :ios` / `AppFrameworkInfo.plist` `MinimumOSVersion` 从 **15.0** 升为 **17.0**（仍可通过 `IOS_DEPLOYMENT_TARGET` 覆盖，且不得默认低于 17.0）。
- CI（`ios-build-core.yml` 等）默认 `IOS_DEPLOYMENT_TARGET` 改为 `17.0`。
- `prepare_ios_project.sh`、`configure_ios_project.rb`、`align_spm_ios_platforms.sh` 及文档中凡写「主 App 默认 15.0」处改为 **17.0**。
- PangbaoWidget Extension 默认仍为 **17.0**（`IOS_WIDGET_DEPLOYMENT_TARGET`）；脚本 MUST NOT 再假设「Runner=15、Widget=17」的分裂叙述为主路径。
- 不降级 / 不替换 `mobile_scanner`；对齐后自然满足其 15.5 地板。
- 不强制抬到 17.2（Push-to-Start 仍用运行时 `#available`）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ios-deployment-target`：主 App 默认部署版本与 Pod/SPM 对齐基线从 15.0 改为 17.0；与 Widget 默认同为 17.0 的叙述更新。

## Impact

- **构建 / CI**：GitHub iOS 流水线、本地 `prepare_ios_project.sh`、`pod install`（解除 `mobile_scanner` 版本冲突）。
- **文档**：`docs/github-ios-ipa.md`、`app/ios/PangbaoWidget/README.md`、相关注释。
- **运行时**：iOS 15–16 设备将无法安装主 App（此前 Widget 本就不能装到 15–16）。
- **Android / 后端**：无。
- **基线**：对照 `openspec/specs/v2.2.2.md`。
