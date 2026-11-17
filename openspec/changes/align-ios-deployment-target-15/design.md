## Context

CI（如 TestFlight `Build signed IPA`）在 Runner 已为 15、`IOS_DEPLOYMENT_TARGET=15.0` 时仍报：

> The package product 'FlutterFramework' requires minimum platform version 13.0 … but this target supports 12.0

此处 **target = SwiftPM package target**（某 `Package.swift` 的 `platforms`），不是 Xcode Runner 的 `IPHONEOS_DEPLOYMENT_TARGET`。仓库约定：

| 表面 | 目标 |
|------|------|
| Runner（主 App） | **15.0** |
| CocoaPods platform / Pod DT | **15.0** |
| `AppFrameworkInfo.plist` MinimumOSVersion | **15.0** |
| ephemeral `Package.swift` platforms | **≥15.0**（与主 App 基线一致） |
| PangbaoWidget Extension | **17.0** |
| WechatOpenSDK vendored | SDK 自报 12.0，不改 |

## Goals / Non-Goals

**Goals:**

- 主 App / Pods / AppFrameworkInfo / ephemeral SPM 统一默认 **15.0**，消除 FlutterFramework 13 vs 12 冲突。
- Widget 保持 **17.0**，签名脚本不覆盖。
- CI 在 SPM 生成之后与 archive 之前均可重复对齐。

**Non-Goals:**

- 不把主 App 降到 13。
- 不改 WechatOpenSDK 的 12.0。
- 不关闭 Swift Package Manager。
- 不永久提交 ephemeral Packages。

## Decisions

### D1：基线固定为 15，而非 13

同前：覆盖 FlutterFramework(13+) / speech_to_text(13+) / ffmpeg(14+)。

### D2：prepare 同步 Podfile + AppFrameworkInfo

- Podfile `platform` + post_install Pod DT = `IOS_DEPLOYMENT_TARGET`。
- `AppFrameworkInfo.plist` 幂等写入 `MinimumOSVersion`，避免缺键时 Flutter 生成落回 12。

### D3：签名脚本分离 Widget DT

Runner ← `IOS_DEPLOYMENT_TARGET`（15）；Widget ← `IOS_WIDGET_DEPLOYMENT_TARGET`（17）。

### D4：厂商 SDK 12.0 不动

### D5：ephemeral Package.swift 显式对齐（CI 关键）

- **选择**：脚本 `align_spm_ios_platforms.sh` 扫描 `ios/Flutter/ephemeral/Packages/**/Package.swift`，将 `.iOS("X")` 中 `X < 基线` 的声明抬到 `IOS_DEPLOYMENT_TARGET`（默认 15.0）；已 ≥ 基线的不降。
- **时机**：① `flutter build ios --config-only` 后；② `flutter_build_ipa_with_spm_align.sh` 用 PATH 包装 `xcodebuild`，在 Flutter 每次调用 archive 前再对齐（Target Integrity 发生在包图解析，必须早于 xcodebuild）；③ Runner Build Phase 作为编译期兜底。
- **理由**：仅抬 Xcode Runner DT 无法修复 SPM Target Integrity；插件 Package.swift 常硬编码 12/11 却依赖 FlutterFramework(13)；`flutter build ipa` 可能在启动 xcodebuild 前重写 ephemeral 包。
- **备选**：关闭 SPM — 与 Widget `home_widget` SPM 路径冲突，不做。

## Risks / Trade-offs

- [ipa 再次生成覆盖 patch] → PATH 包装 xcodebuild，保证解析前对齐；Build Phase 兜底。
- [误抬第三方合法低版本包] → 仅抬低于基线且存在于 ephemeral 树内的声明；基线与主 App 一致。
- [AppFrameworkInfo 被 flutter create 冲掉] → prepare 幂等补写。

## Migration Plan

1. 提交 `AppFrameworkInfo.plist` MinimumOSVersion=15.0；prepare 保证之。
2. 新增 `align_spm_ios_platforms.sh`；workflow 两处调用。
3. 文档补充「SPM target ≠ Runner target」。
4. 重跑 TestFlight workflow 验证 Build signed IPA。

回滚：撤脚本调用与 plist 键即可。

## Open Questions

- 无。
