## ADDED Requirements

### Requirement: 提审清单 MUST 包含 App Store 语言标签自检

The release checklist MUST include verification that the App Store product page language field reflects Simplified Chinese after the localized build is processed.

`docs/github-ios-ipa.md` 或 `docs/ios-github-actions-checklist.md` 中的 App Store 提审/发布核对清单 MUST 增补必检项：上传声明 `zh-Hans` 的新 build 并经 ASC 处理完成后，确认 App Store 商品页「信息 → 语言」为中文（简体中文），不得仍为仅「英语」。

#### Scenario: 提审前语言标签核对

- **WHEN** 运营人员准备基于新 IPA 提交 App Store 审核
- **THEN** 清单 MUST 包含「确认商品页语言为中文」勾选项
- **AND** 核对 MUST 在 ASC build 处理完成之后进行（非上传瞬间）

#### Scenario: 文档说明语言字段来源

- **WHEN** 维护人员阅读 iOS 发布文档
- **THEN** 文档 MUST 说明 App Store「语言」来自 IPA bundle 本地化声明，而非仅 App Store Connect 商品描述语言
- **AND** MUST 指向 `prepare_ios_project.sh` 的 `zh-Hans` 注入为修复手段
