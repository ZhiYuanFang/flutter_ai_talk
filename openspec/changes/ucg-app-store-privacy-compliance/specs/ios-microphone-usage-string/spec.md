## MODIFIED Requirements

### Requirement: iOS 构建产物 MUST 包含具体麦克风用途说明

The iOS release build MUST set `NSMicrophoneUsageDescription` in `Info.plist` to a user-facing string that explains why the app needs microphone access, includes a concrete usage example, and states that the microphone is not used for background recording or advertising. Empty environment variables MUST fall back to script defaults.

iOS 发布构建 MUST 在 `Info.plist` 写入 `NSMicrophoneUsageDescription`；文案须说明麦克风用途、给出**具体使用示例**，并明确仅用于语音输入、不会在后台录音或用于广告。当 `IOS_MICROPHONE_USAGE_DESCRIPTION` 未设置或为空白字符串时，MUST 回退至 `prepare_ios_project.sh` 内置默认文案，不得写入空值。

#### Scenario: CI 未覆盖时使用默认文案

- **WHEN** 执行 `app/tool/ci/prepare_ios_project.sh` 且未设置 `IOS_MICROPHONE_USAGE_DESCRIPTION` 或该值为空白字符串
- **THEN** 写入 `Info.plist` 的 `NSMicrophoneUsageDescription` MUST 为脚本默认文案
- **AND** 默认文案 MUST 包含育儿语音记录示例（如「宝宝刚刚喝了 120ml 奶」）
- **AND** 文案 MUST 说明麦克风用于将用户说出的育儿记录转换为文字并保存

#### Scenario: CI 通过环境变量覆盖

- **WHEN** 构建流程设置非空且非空白 `IOS_MICROPHONE_USAGE_DESCRIPTION`
- **THEN** `prepare_ios_project.sh` MUST 将该值写入 `NSMicrophoneUsageDescription`
- **AND** 覆盖值仍须满足「具体用途 + 示例 + 非后台/非广告」的审核语义（由发布检查清单人工确认）

#### Scenario: App Store 审核读取权限弹窗

- **WHEN** 用户在 iOS 上首次触发需要麦克风的语音输入功能且系统展示权限请求
- **THEN** 系统弹窗显示的说明文字 MUST 与 `Info.plist` 中更新后的 `NSMicrophoneUsageDescription` 一致
- **AND** 弹窗 MUST NOT 显示空白说明

### Requirement: iOS 构建产物 MUST 包含语音识别用途说明且空值回退

The iOS release build MUST set non-empty `NSSpeechRecognitionUsageDescription` in `Info.plist`, falling back to script default when the environment variable is unset or blank.

`NSSpeechRecognitionUsageDescription` MUST 非空；当 `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION` 未设置或为空白字符串时，MUST 回退至脚本默认文案。

#### Scenario: 语音识别权限默认文案

- **WHEN** 执行 `prepare_ios_project.sh` 且 `IOS_SPEECH_RECOGNITION_USAGE_DESCRIPTION` 未设置或为空
- **THEN** MUST 写入默认语音识别用途说明（将语音转换为文字）

#### Scenario: 文档示例不得引导笼统麦克风文案

- **WHEN** 维护者参考 `docs/ios-github-actions-checklist.md` 填写 GitHub Secret
- **THEN** 麦克风示例 MUST 与合规默认句式一致或更具体
- **AND** MUST NOT 使用「需要麦克风权限以支持语音输入与录音」等笼统描述作为推荐示例
