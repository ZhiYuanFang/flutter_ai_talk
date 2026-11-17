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

### D5：ephemeral + pub-cache 消费方 Package.swift 对齐 + 直调 archive

- **选择**：`align_spm_ios_platforms.sh` 扫描 ephemeral（含 symlink）、`package_config.json` 包根、`$PUB_CACHE/**/darwin|ios/**/Package.swift` 中依赖 `FlutterFramework` 的清单；消费方抬到 15；`FlutterFramework` 仅 ≥13。残留则失败。
- **已知凶手**：`photo_manager` 源码 `.iOS("9.0")`（Xcode 钳成 12），archive 时才以 `.packages/photo_manager @ local` 出现；仅扫 ephemeral 会 `scanned=2` 漏掉。
- **IPA 路径**：`config-only` → ensure Widget → **align** → `xcodebuild archive` → `exportArchive`（不用 PATH 包装）。
- **备选**：关闭 SPM — 与 Widget 冲突，不做。

## Risks / Trade-offs

- [config-only 冲掉 Widget SPM] → IPA 脚本在 align 前再跑 ensure。
- [误抬 FlutterFramework 产品下限] → 对 FlutterFramework 只保证 ≥13，不抬到 15。
- [插件源在 pub-cache，ephemeral 未 materialize] → 同步 patch PUB_CACHE / package_config 根。
- [AppFrameworkInfo 被 flutter create 冲掉] → prepare 幂等补写。

## Migration Plan

1. 提交 AppFrameworkInfo / prepare / align / IPA 直调 archive 脚本与 workflow 接线。
2. 重跑 TestFlight：日志须有 `[IPA] 3/5 align` 与 `align_spm_ios_platforms: scanned=`，且无 FlutterFramework vs 12。

回滚：撤脚本调用与 plist 键即可。

## Open Questions

- 无。
