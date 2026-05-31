# Design: ios-testflight-internal-only-mode

## Context

当前工作流 [.github/workflows/build-ios-ipa.yml](../../../.github/workflows/build-ios-ipa.yml) 通过 `export_method`（development/ad-hoc/app-store）与 `upload_to_testflight`（布尔）组合表达构建与上传流程，但缺少“发布意图”这一抽象层。结果是：

- 用户想做“仅内部 TestFlight”时，需要自行理解 `app-store + upload=true` 的隐式语义。
- 上传动作目前设置 `--skip_waiting_for_build_processing true`，流程会在上传后结束，内部组分配与可用性确认依赖手工操作。
- 错误提示以技术参数为中心，不够贴近“我要内部测试”这类目标导向输入。

该变更面向 GitHub Actions 手工触发使用者，目标是在不改变签名体系的前提下，降低内部测试路径的误操作率。

## Goals / Non-Goals

**Goals:**

- 提供显式 `testflight_internal_only` 模式，直接表达“仅内部测试”意图。
- 统一约束：内部测试模式必须走 `app-store` 导出与 TestFlight 上传。
- 在上传后尽可能自动分配到指定内部测试组；缺失配置时给出清晰失败或降级提示。
- 通过文档明确三类路径差异：仅导出 IPA、仅内部 TestFlight、TestFlight/上架准备。

**Non-Goals:**

- 不引入新的 iOS 证书体系或替代当前签名实现。
- 不在本次变更中实现 App Store 提审自动化（提交审核、元数据上传、发布定时等）。
- 不变更 Android 或其他平台工作流。

## Decisions

### 决策 1：引入“发布意图”输入而不是继续扩展布尔参数

- 采用单一枚举输入（示例：`release_mode`）承载用户目标，候选值：`ipa_only`、`testflight_internal_only`、`testflight_and_appstore`。
- 保留 `export_method` 作为底层签名参数，但在 `testflight_*` 模式下由流程强约束为 `app-store`。

备选方案：继续增加布尔参数（如 `internal_only=true`）。

- 未采纳原因：布尔组合会继续增长状态空间，用户仍需自行推断参数联动，认知负担高。

### 决策 2：内部测试分配采用“可配置目标组 + 显式校验”

- 为 `testflight_internal_only` 预留内部组配置（组名或组 ID）。
- 若开启内部测试模式但未提供组配置，流程应明确失败并提示所需配置，避免“上传成功但不可测”的假阳性结果。

备选方案：上传后不分配，全部手工去 App Store Connect 操作。

- 未采纳原因：与“Internal Only 一键化”目标冲突，且难以及时发现遗漏。

### 决策 3：保留 fastlane 上传链路，扩展到内部组分配

- 维持现有 fastlane 依赖与 API Key 鉴权方式，减少迁移风险。
- 在该链路上增加内部组分配/可见性校验步骤，并将日志结构化输出（模式、IPA 路径、目标组、结果）。

备选方案：改回 `xcodebuild -exportArchive` 的 upload destination 或其他上传工具。

- 未采纳原因：当前仓库已验证 fastlane 路径稳定，切换工具会引入额外不确定性。

## Risks / Trade-offs

- [Risk] App Store Connect API 对内部组分配能力或参数存在账号差异 → Mitigation：在前置校验中增加能力探测，失败时给出最小手工补救步骤。
- [Risk] 新旧参数并存期间用户仍可能误配 → Mitigation：在验证阶段提供互斥规则与迁移提示，文档给出“推荐只用 `release_mode`”示例。
- [Risk] 上传后处理异步导致“已上传但暂不可分配” → Mitigation：加入有限重试与超时策略，超时时输出明确下一步操作指引。
- [Risk] 额外 API 操作增加失败面 → Mitigation：将“上传成功”与“分配成功”拆分结果展示，便于定位与重跑。

## Migration Plan

1. 增加输入与校验逻辑，保证旧参数组合仍可运行（短期兼容）。
2. 新增内部测试模式文档与示例，标注推荐路径。
3. 观察一段时间后评估是否将旧布尔输入标记为废弃（仅文档层提示，不立即移除）。
4. 若内部组分配步骤失败，可通过关闭内部分配步骤回退到“上传后手工分配”的现有可用流程。

## Open Questions

- 内部测试组配置优先使用“组名”还是“组 ID”？是否需要同时支持二者？
- 内部分配失败时，是否允许“上传成功即通过”并仅告警，而非整体失败？
- `testflight_and_appstore` 在当前阶段是否仅表示“上传并保留上架准备”，还是需要追加元数据完整性检查？
