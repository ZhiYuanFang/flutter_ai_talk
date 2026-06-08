## ADDED Requirements

### Requirement: App Store Connect 截图 MUST 含原生 iOS 状态栏

App Store listing screenshots MUST be captured from real iOS devices or Simulator with the native iOS status bar visible, per Apple Guideline 2.3.10.

提审前 MUST 按清单核对：所有 iPhone 截图来自真机或 Simulator，且可见原生 iOS 状态栏（时间、信号、电量等）；不得使用纯 App 内容裁剪图或 Android/Web 素材。

#### Scenario: 提审前截图自检

- **WHEN** 运营人员准备 v1.0.2 App Store 截图
- **THEN** 每张截图 MUST 包含顶部原生 iOS 状态栏
- **AND** MUST NOT 使用无状态栏的 marketing 纯界面图

#### Scenario: 多设备尺寸

- **WHEN** ASC 要求 6.7"、6.5"、5.5" 等尺寸截图
- **THEN** 每个尺寸 MUST 独立截取，且均含原生状态栏

### Requirement: 提审清单 MUST 覆盖权限、隐私 URL 与 build 选择

A release checklist MUST document manual ASC steps: privacy policy URL, App Privacy labels cross-check, permission strings verification, and build selection before Submit for Review.

`docs/` 或变更 tasks 中 MUST 提供可勾选的提审清单，涵盖：隐私政策 URL 可访问、App Privacy 与政策一致、`.ipa` 权限字符串已验证、已选正确 build。

#### Scenario: 提审前清单执行

- **WHEN** 提交 App Store 审核前
- **THEN** 负责人 MUST 完成清单全部必选项
- **AND** 清单 MUST 包含 Guideline 2.3.10 截图项与 5.1.1 权限文案项
