# Tasks: ios-testflight-internal-only-mode

## 1. 工作流输入与校验重构

- [x] 1.1 在 `.github/workflows/build-ios-ipa.yml` 中新增发布意图输入（如 `release_mode`）并定义模式选项。
- [x] 1.2 在“Validate workflow configuration”阶段实现模式与参数联动校验（`testflight_internal_only` 与 `app-store` 约束、互斥提示、迁移提示）。
- [x] 1.3 保持旧输入短期兼容，补充旧参数路径的告警文案，确保已有手工触发方式不被破坏。

## 2. 内部 TestFlight 分配能力

- [x] 2.1 设计并接入内部测试组配置输入/Secret（组名或组 ID），并在校验阶段检查其可用性。
- [x] 2.2 在现有 fastlane 上传链路后新增内部组分配步骤，输出结构化日志（模式、目标组、分配结果）。
- [x] 2.3 为上传后异步处理增加有限重试与超时策略，并给出“上传成功但分配失败”时的手工补救说明。

## 3. 文档与可操作性

- [x] 3.1 更新 `docs/github-ios-ipa.md`，新增“TestFlight Internal Only”模式说明、参数示例与故障排查。
- [x] 3.2 更新 `docs/ios-github-actions-checklist.md`，增加内部测试快速路径与必需 Secret 清单。
- [x] 3.3 在工作流说明中补充模式对照表，明确“仅导出 IPA / 仅内部 TestFlight / TestFlight&上架准备”边界。

## 4. 验证与回归

- [x] 4.1 验证 `ipa_only` 路径：可成功产物归档且不触发 TestFlight 上传。
- [x] 4.2 验证 `testflight_internal_only` 路径：可成功上传并完成内部分配（或按规范给出显式降级结果）。
- [x] 4.3 验证异常路径：缺少内部组配置、参数冲突、API 鉴权失败时，错误信息可直接指导修复。
