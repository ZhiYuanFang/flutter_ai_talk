## Context

主 App 默认 `IOS_DEPLOYMENT_TARGET=15.0`（Podfile / Runner / `AppFrameworkInfo.plist` / CI）。Widget Extension 已默认 **17.0**。`mobile_scanner` 6.0.2 的 podspec 要求 **iOS 15.5**，导致 CI `pod install` 失败。Live Activity 产品路径：UI 16.1+、观察 16.2+、Push-to-Start 17.2+（运行时 `#available`）；Extension 因交互小组件 Intent 已锁 17。

基线：`openspec/specs/v2.2.2.md` capability `ios-deployment-target`。

## Goals / Non-Goals

**Goals:**

- 主 App 默认部署版本与对齐脚本基线改为 **17.0**，与 Widget 默认同级。
- 一次消除 `mobile_scanner` 相对 15.0 的 CocoaPods 冲突。
- 更新规格与文档，去掉「Runner=15 / Widget=17」作为主路径叙述。

**Non-Goals:**

- 不把主 App 抬到 17.2（Push-to-Start 继续运行时门控）。
- 不降级 / 替换 `mobile_scanner` 或 ML Kit。
- 不改 Android、不改 Live Activity 业务协议。
- 不删除现有 `#available(iOS 16.x/17.2)` 防护（在 DT=17 下仍无害）。

## Decisions

1. **默认抬到 17.0，而非 15.5**  
   - 15.5 仅够扫码；产品已以 Widget/LA 为能力面，15–16 本就不能装 Extension。  
   - 替代：仅 Podfile 15.5 → 否决（与「对齐 LA/Widget」不符，且文档/签名仍分裂）。

2. **单一环境变量仍为 `IOS_DEPLOYMENT_TARGET`**  
   - 默认值改 `17.0`；覆盖值 MUST NOT 默认低于 17。  
   - Widget 继续 `IOS_WIDGET_DEPLOYMENT_TARGET`（默认 17.0）；主 App 升到 17 后两者数值相同，但脚本仍分键，避免误把 Widget 改回更低。

3. **SPM align 基线跟随主 App**  
   - `align_spm_ios_platforms.sh` 用 `IOS_DEPLOYMENT_TARGET`（现默认变 17）；`FlutterFramework` 仍只保证 ≥13，不抬到 17。

4. **提交内 xcodeproj / plist 与 prepare 幂等一致**  
   - 仓库已有 `AppFrameworkInfo.plist` MinimumOSVersion、Runner DT 须改为 17.0；CI prepare 继续幂等写入。

## Risks / Trade-offs

- [Risk] iOS 15–16 用户无法安装主 App → Mitigation：与「装不上 Widget」现状一致；发布说明可注明最低 iOS 17。  
- [Risk] 某处硬编码 `15.0` 漏改导致 CI 仍 15 → Mitigation：tasks 覆盖 CI env、prepare 默认、文档、规格；apply 时全局搜 `15.0` 于 iOS 部署语境。  
- [Risk] 覆盖 env 仍被设成 15.x → Mitigation：规格要求默认不得低于 17；文档标明覆盖下限。

## Migration Plan

1. 合并本 change 后跑 iOS CI：`prepare` → `pod install` → archive。  
2. 确认 `mobile_scanner` 不再报 higher minimum deployment target。  
3. 回滚：恢复 `IOS_DEPLOYMENT_TARGET=15.0` 会再次撞 `mobile_scanner`，须同步降扫码依赖（不推荐）。

## Open Questions

（无；目标版本 17.0 已由产品确认。）
