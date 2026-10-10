## ADDED Requirements

### Requirement: Growth ask composer MUST auto-grow with max height 120 and bottom follow

While growth-trajectory asking text input is visible, the answer field MUST grow with content up to a maximum height of 120 logical pixels. When content exceeds that height, the field MUST become scrollable; programmatic or voice-driven text growth that keeps the caret/content at the end MUST scroll to the bottom. After voice input ends, the user MUST be able to scroll within the field to review and edit. 成长轨迹追问文本框 **必须** 随内容增高且最大高度 120；超高可滚且跟底写入时滚到底；语音结束后 **必须** 可滚动查看编辑。

#### Scenario: Short text stays compact

- **WHEN** 追问输入文案较少、未达 120 高度
- **THEN** 输入区高度 MUST 随内容增高且 MUST NOT 无故占满 120

#### Scenario: Long text caps and scrolls

- **WHEN** 文案使内容高度超过 120
- **THEN** 输入区高度 MUST 封顶为 120 且 MUST 可纵向滚动

#### Scenario: Voice append follows bottom

- **WHEN** 按住说话写入转写使内容超过 120 且用户未主动上翻离开底部
- **THEN** 客户端 MUST 将滚动位置跟到接近底部以便看到最新字

### Requirement: Growth ask composer MUST use feature-accent light glass chrome

The visible ask text field shell and the hold-to-talk control MUST use light glass styling tinted by the growth feature accent from `resolveFeatureColor` (or equivalent catalog accent). Default undecorated Material outline-only chrome MUST NOT be the sole final look for these controls. 追问输入壳与按住条 **必须** 使用成长功能色浅玻璃；**不得** 仅以默认灰描边 Outline 作为最终主视觉。

#### Scenario: Accent glass on free-text ask

- **WHEN** 用户处于 free_text 追问且文本输入可见
- **THEN** 输入框与按住说话控件 MUST 呈现功能色浅玻璃样式

### Requirement: Hold-to-talk MUST show shared VoiceLevelBars on both sides while listening

While the user is pressing the growth ask hold-to-talk control, the client MUST show the shared `VoiceLevelBars` (or renamed equivalent atom) on both the left and right of the control, driven by smoothed speech level from the active recognizer `onLevel`. When not listening, flanking bars MAY be hidden or idle at zero. 按住说话时 **必须** 在控件左右展示共享能量柱并由 onLevel 平滑驱动；未按住时可隐藏或归零。

#### Scenario: Listening shows side bars

- **WHEN** 用户在成长追问按住说话且采集已开始
- **THEN** 按住控件左右 MUST 各显示 VoiceLevelBars，且 level 随语音能量变化

#### Scenario: Release hides or idles bars

- **WHEN** 用户松手结束采集
- **THEN** 左右能量柱 MUST 隐藏或回到空闲（level 0），且 MUST NOT 自动提交答案
