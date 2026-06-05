## ADDED Requirements

### Requirement: iOS 构建产物 MUST 包含具体麦克风用途说明
The iOS release build MUST set `NSMicrophoneUsageDescription` in `Info.plist` to a user-facing string that explains why the app needs microphone access, includes a concrete usage example, and states that the microphone is not used for background recording or advertising.

iOS 发布构建必须在 `Info.plist` 中写入 `NSMicrophoneUsageDescription`，文案须向用户说明麦克风用途、给出**具体使用示例**，并明确麦克风仅用于语音输入、不会在后台录音或用于广告；不得使用「需要麦克风权限以支持语音输入与录音」等笼统描述。

#### Scenario: CI 未覆盖时使用默认文案
- **WHEN** 执行 `app/tool/ci/prepare_ios_project.sh` 且未设置 `IOS_MICROPHONE_USAGE_DESCRIPTION`
- **THEN** 写入 `Info.plist` 的 `NSMicrophoneUsageDescription` 必须包含育儿语音记录示例（如「宝宝刚刚喝了 120ml 奶」）
- **AND** 文案必须说明麦克风用于将用户说出的育儿记录转换为文字并保存

#### Scenario: CI 通过环境变量覆盖
- **WHEN** 构建流程设置非空 `IOS_MICROPHONE_USAGE_DESCRIPTION`
- **THEN** `prepare_ios_project.sh` 必须将该值写入 `NSMicrophoneUsageDescription`
- **AND** 覆盖值仍须满足「具体用途 + 示例 + 非后台/非广告」的审核语义（由发布检查清单人工确认）

#### Scenario: App Store 审核读取权限弹窗
- **WHEN** 用户在 iOS 上首次触发需要麦克风的语音输入功能且系统展示权限请求
- **THEN** 系统弹窗显示的说明文字必须与 `Info.plist` 中更新后的 `NSMicrophoneUsageDescription` 一致
- **AND** 用户可从中理解麦克风用于育儿语音转文字，而非模糊的全局录音权限
