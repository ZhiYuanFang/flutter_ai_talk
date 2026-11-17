## Why

Xcode / SPM 报错「`FlutterFramework` 要求 iOS 13.0，但当前 target 仍为 12.0」。本仓库 Runner / CI 已是 **15.0**，但真正失败点往往在 **SwiftPM 包图**：`ios/Flutter/ephemeral/Packages/**/Package.swift` 仍声明 `.iOS("12.0")`（或 `AppFrameworkInfo.plist` 缺 `MinimumOSVersion` 导致生成物落回 12），与 `FlutterFramework`（≥13）冲突。仅改 Xcode Runner DT / Widget 签名脚本无法消除该 CI 错误。

## What Changes

- 明确主 App（Runner）与 CocoaPods `platform` / Pod `IPHONEOS_DEPLOYMENT_TARGET` 统一为 **15.0**（可用 `IOS_DEPLOYMENT_TARGET` 覆盖，默认不得低于 15）。
- 确保 `prepare_ios_project.sh` 写入 Podfile 15，并同步 Pods；提交侧 `Runner.xcodeproj` 保持 15.0。
- **补齐** `AppFrameworkInfo.plist` 的 `MinimumOSVersion = 15.0`，并在 prepare 中幂等保证，避免 Flutter 生成 SPM 包时落回 12。
- **CI / 本地**：在 `flutter build ios --config-only` 之后、以及 `flutter build ipa` 之前，将 ephemeral `Package.swift` 中低于基线的 `.iOS("…")` 抬到与 `IOS_DEPLOYMENT_TARGET` 一致（默认 15.0）。
- PangbaoWidget Extension 继续 **17.0**，不得被签名脚本误写成 15。
- 厂商 `WechatOpenSDK` 自身 12.0 **不改**。
- 文档说明：报错里的「target」可能是 SPM package，不是 Runner；对齐默认 15，勿只升到 13。

## Capabilities

### New Capabilities

- `ios-deployment-target`: 约定 iOS 主 App / Pods / Widget / AppFrameworkInfo / ephemeral SPM Package.swift 的最低部署版本基线，以及 prepare / 签名 / CI 如何同步这些值。

### Modified Capabilities

- （无）现有合并基线中无独立 iOS deployment target 能力；本次新增而非改写既有 Requirement。

## Impact

- `app/ios/Flutter/AppFrameworkInfo.plist`
- `app/ios/Runner.xcodeproj/project.pbxproj`
- `app/tool/ci/prepare_ios_project.sh`
- `app/tool/ci/align_spm_ios_platforms.sh`、`flutter_build_ipa_with_spm_align.sh`（新建）
- `app/tool/ci/configure_ios_project.rb`、`ensure_pangbao_widget_target.rb`（Runner Build Phase）
- `.github/workflows/ios-build-core.yml`（config-only 后 align；IPA 走 xcodebuild 包装脚本）
- `docs/github-ios-ipa.md`、`app/ios/PangbaoWidget/README.md`
- CI：`Build signed IPA` 不再因 FlutterFramework 13 vs SPM 12 失败
