# Design: ios-app-icon-match-android

## Context

当前项目 Android 端图标来源已明确，iOS 打包后却出现与 Android 不一致的图标，说明 iOS 图标生成链路与 Android 图标源之间没有建立稳定约束。现有流程涉及 `pubspec.yaml`、`flutter_launcher_icons`、iOS `AppIcon.appiconset` 与 CI 打包步骤，任何一处偏差都会导致最终 IPA 图标漂移。

## Goals / Non-Goals

**Goals:**

- 建立“iOS 图标必须与 Android 图标同源”的明确配置约束。
- 在本地与 CI 中稳定产出一致的 iOS 图标资源，避免手工替换带来的不确定性。
- 增加最小可执行校验，能在打包前发现图标未同步问题。

**Non-Goals:**

- 不更换品牌图标设计稿，不改变图标视觉规范本身。
- 不在本次引入新的图标生成工具链（优先复用现有 `flutter_launcher_icons`）。
- 不扩展到通知图标、启动图或其他品牌资源一致性治理。

## Decisions

### 决策 1：统一图标源到单一主资产

- 采用 Android 当前主图标资产（`assets/images/app_icon.png`）作为 iOS 图标生成唯一来源。
- 要求 `pubspec.yaml` 中 iOS 图标配置与 Android 保持同源，避免双源维护。

备选方案：Android 和 iOS 维持各自独立源文件。

- 未采纳原因：高概率出现一端更新另一端遗漏，导致发布结果不一致。

### 决策 2：以生成替代手改

- 使用 `flutter_launcher_icons` 统一生成 iOS 图标集，不接受手工修改 `AppIcon.appiconset` 作为长期方案。
- 在 CI 中明确“若 iOS 图标集缺失或过旧则重新生成/失败提示”。

备选方案：直接提交静态 iOS 图标目录并长期手工维护。

- 未采纳原因：尺寸矩阵复杂、易遗漏，且与 Android 同步成本高。

### 决策 3：增加发布前校验

- 在 iOS 打包流程增加图标一致性检查（至少检查关键目标文件存在，并与源图版本对齐策略一致）。
- 当发现图标资产不一致时，给出明确错误信息和修复指引。

备选方案：仅依赖人工视觉验收。

- 未采纳原因：人工检查成本高且不稳定，容易在快节奏发布中漏检。

## Risks / Trade-offs

- [Risk] 源图分辨率或透明边距不满足 iOS 视觉要求 → Mitigation：在任务中加入源图规格检查与一次性修正。
- [Risk] 本地生成与 CI 生成结果差异 → Mitigation：固定工具版本并在 CI 输出生成日志。
- [Risk] 旧缓存导致看似未生效 → Mitigation：加入构建清理与测试设备重装指引。

## Migration Plan

1. 对齐 `pubspec.yaml` 的 iOS 图标配置到 Android 同源资产。
2. 重新生成 iOS 图标集并提交到仓库。
3. 在 CI 打包前增加图标检查（必要时触发重新生成或失败提示）。
4. 使用 `ipa_only` 与 `testflight_internal_only` 各验证一轮，确认安装后图标一致。
5. 若出现回归，回退到上一版图标资产与配置并重新打包。

## Open Questions

- 当前 Android 主图是否已满足 iOS 圆角留白与视觉安全区要求，是否需要设计再导出一版同视觉同内容的高分辨率源图？
- 是否需要把图标一致性校验结果写入发布日志，便于后续审计与追踪？
