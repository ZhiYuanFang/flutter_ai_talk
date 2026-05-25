## ADDED Requirements

### Requirement: 输入模式切换后跟底用户须重锚至最新记录

The system SHALL re-anchor the home history list to the latest records after the bottom input panel height changes due to an input mode switch, when the user was following the latest. 当用户切换首页输入模式（语音 / 文字 / 按钮）导致底部输入区高度变化时，若切换前用户处于**跟底**状态（正在查看最新记录），系统 MUST 在布局稳定后将历史列表滚回底部，使最新记录仍位于可视区内。

#### Scenario: 从文字模式切到语音球且跟底

- **WHEN** 用户在文字输入模式下历史列表处于跟底（`_followLatest == true`），且通过切换器切换到语音球模式
- **THEN** 底部面板高度动画完成后，历史列表 MUST 自动滚至底部，最新记录 MUST 可见，无需用户手动滚动

#### Scenario: 从按钮模式切到语音球且跟底

- **WHEN** 用户在按钮模式下历史列表处于跟底，且切换到语音球模式
- **THEN** 系统 MUST 同样自动滚至底部并保持最新记录可见

#### Scenario: 用户已上滑浏览历史

- **WHEN** 用户已主动上滑且距列表底部超过跟底阈值（非跟底状态）
- **THEN** 切换输入模式后系统 MUST NOT 强制滚到底部，须保持用户当前浏览位置

#### Scenario: 距底部在阈值内

- **WHEN** 用户距列表底部不超过跟底阈值（与 `HomeHistoryScroll.followBottomThreshold` 一致）
- **THEN** 切换模式后系统 MUST 滚至底部并恢复跟底状态

### Requirement: 重锚须在布局稳定后执行

The system MUST schedule history re-anchoring after the input panel layout has updated following a mode switch. 系统 MUST 在输入模式切换触发布局更新**之后**再执行滚底（至少一次 post-frame；可复用既有 `scrollToBottom` 二次 post-frame），以避免在 `maxScrollExtent` 未稳定时滚错位置。

#### Scenario: 面板高度动画期间

- **WHEN** 底部 `AnimatedContainer` 正在改变高度
- **THEN** 滚底 MUST 在布局帧完成后再执行，并与面板动画协调（默认 220ms easeOutCubic 或 `jumpTo` 当系统禁用动画时）

#### Scenario: 历史列表为空

- **WHEN** 无历史记录或列表尚未挂载 `ScrollController`
- **THEN** 系统 MUST NOT 抛出错误；重锚为 no-op

### Requirement: 覆盖全部输入模式切换入口

The system MUST apply re-anchoring for every code path that changes `HomeInputChannel` on the home screen. 凡变更首页 `_inputChannel` 的路径（含 `HomeInputModeDock` 选择与本地持久化恢复）MUST 在 channel 实际变更后触发同一重锚逻辑；同一 channel 重复选择 MUST NOT 触发。

#### Scenario: Dock 切换

- **WHEN** 用户通过贴边切换器选择不同于当前的输入模式
- **THEN** 系统 MUST 执行跟底重锚（若满足跟底条件）

#### Scenario: 重复选择当前模式

- **WHEN** 用户选择已处于激活状态的输入模式
- **THEN** 系统 MUST NOT 触发滚底重锚
