## Context

- 胖宝 App 运行时 UI 已固定 `locale: zh_CN`，App Store 商品页描述亦为中文。
- [中国区商品页](https://apps.apple.com/cn/app/%E8%83%96%E5%AE%9D/id6774418472)「信息 → 语言」仍显示 **英语**，因 IPA 仅声明 English（Flutter 默认 `CFBundleDevelopmentRegion=en`，无 `zh-Hans.lproj`）。
- 现有 CI 链：`ios-build-core.yml` → `prepare_ios_project.sh` → `flutter build ipa` → `fastlane pilot upload`；脚本已注入权限文案与 `CFBundleDisplayName`，未处理 bundle 本地化。
- `ios/` 工程在 CI 中由 `flutter create` 按需生成，本地化须在 **每次构建前** 由脚本写入，不宜仅依赖未入库的本地 Xcode 手改。

## Goals / Non-Goals

**Goals:**

- App Store 商品页「语言」在 ASC 处理新 build 后显示 **简体中文**（或等效中文标签）。
- 变更集中在 `prepare_ios_project.sh`，与现有 iOS 发布 workflow 无缝集成。
- 文档说明「语言标签来自 binary」与验证步骤。

**Non-Goals:**

- 不通过 `fastlane deliver` 同步 ASC 商品文案（已是中文）。
- 不新增英文 `.lproj` 或完整 i18n 资源（除非后续产品需要双语商店标签）。
- 不改变 Android / Web 语言声明。
- 不修改 App 内 Flutter 国际化架构。

## Decisions

### 1. 在 `prepare_ios_project.sh` 写入 plist + 生成 `zh-Hans.lproj`

**Decision**：在同一 Python 块（或紧随其后的块）中：

- 设置 `CFBundleDevelopmentRegion` = `zh-Hans`
- 设置 `CFBundleLocalizations` = `['zh-Hans']`（仅中文；若未来需显示「中文、英语」可再加 `en`）
- 创建 `ios/Runner/zh-Hans.lproj/InfoPlist.strings`，内容至少：

  ```text
  CFBundleDisplayName = "胖宝";
  CFBundleName = "胖宝";
  ```

  若 `IOS_APP_DISPLAY_NAME` 已设置，优先使用该值。

**Why**：Apple 从 bundle 内 `.lproj` + `CFBundleLocalizations` 推断 App 支持语言；仅改 `DevelopmentRegion` 而无 `.lproj` 可能仍被识别为 English。

**Alternatives**：

- 仅改 ASC Primary Language → 不改 binary，**无法**修复「语言：英语」标签。
- 在仓库提交完整 `ios/` 并手改 Xcode → CI `flutter create` 会覆盖/不一致，维护成本高。

### 2. Xcode `knownRegions`（可选增强）

**Decision**：在 `configure_ios_project.rb` 或 `prepare_ios_project.sh` 中向 `project.pbxproj` 的 `knownRegions` 追加 `zh-Hans`，并将 `developmentRegion` 设为 `zh-Hans`（若尚未设置）。

**Why**：与 plist 声明一致，避免 Xcode 导出时剥离未注册 region。

**Alternatives**：仅 plist — 多数场景足够；若首版验证失败再加 pbxproj 补丁。

### 3. 不新增 workflow 步骤

**Decision**：复用现有 `Prepare iOS project metadata` step，不新增 job。

**Why**：本地化是构建前 metadata 的一部分，与权限字符串注入同生命周期。

### 4. 验证方式

**Decision**：tasks 中要求：

1. 本地或 CI 构建后检查 `Info.plist` 与 `zh-Hans.lproj` 存在；
2. 上传 TestFlight/App Store build 后，在 ASC build 详情查看 **Included Localizations** 含 Chinese (Simplified)；
3. 处理完成后检查 App Store 商品页「语言」字段。

## Risks / Trade-offs

- **[Risk] 仅声明 zh-Hans 后，海外用户商店页也可能显示「仅中文」** → 符合当前产品定位；若需双语标签可后续在 `CFBundleLocalizations` 加 `en`。
- **[Risk] ASC 语言标签更新滞后** → 需等新 build 处理完成，非即时；文档中说明。
- **[Risk] `flutter create` 再生工程时覆盖 pbxproj** → 脚本 idempotent 写入 plist/lproj；knownRegions 补丁需每次 CI 执行。

## Migration Plan

1. 合并脚本变更 → 跑 `build-ios-testflight` 或 `appstore` 上传新 build。
2. 等待 ASC 处理 build → 确认 Included Localizations。
3. 检查 App Store 商品页语言字段 → 提审/发布。

回滚：移除 plist/lproj 写入逻辑，重新上传 build 即可恢复 English 标签（不推荐）。

## Open Questions

- 是否在 `CFBundleLocalizations` 中同时保留 `en` 以显示「中文、英语」— **v1 仅 zh-Hans**，按产品「中文 App」定位。
