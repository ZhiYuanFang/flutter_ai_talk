## MODIFIED Requirements

### Requirement: 输入模式切换后跟底用户须重锚至最新记录

The system SHALL re-anchor the home history list to the latest records after the bottom input panel height changes due to an input mode switch, when the user was following the latest. 当用户切换首页输入模式（移动端 **语音 / 按钮**；Web 仍可为语音 / 文字）导致底部输入区高度变化时，若切换前用户处于**跟底**状态，系统 MUST 在布局稳定后将历史列表滚回底部。

#### Scenario: 从按钮模式切到语音球且跟底

- **WHEN** 用户在按钮模式下历史列表处于跟底，且通过 dock 轮转到语音球模式
- **THEN** 底部面板高度动画完成后，历史列表 MUST 自动滚至底部，最新记录 MUST 可见

#### Scenario: 从语音球切到按钮模式且跟底

- **WHEN** 用户在语音模式下历史列表处于跟底，且通过 dock 轮转到按钮模式
- **THEN** 系统 MUST 同样自动滚至底部并保持最新记录可见

#### Scenario: 用户已上滑浏览历史

- **WHEN** 用户已主动上滑且距列表底部超过跟底阈值（非跟底状态）
- **THEN** 切换输入模式后系统 MUST NOT 强制滚到底部，须保持用户当前浏览位置

#### Scenario: 距底部在阈值内

- **WHEN** 用户距列表底部不超过跟底阈值（与 `HomeHistoryScroll.followBottomThreshold` 一致）
- **THEN** 切换模式后系统 MUST 滚至底部并恢复跟底状态
