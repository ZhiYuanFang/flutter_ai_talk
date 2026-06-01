## ADDED Requirements

### Requirement: Web 端 Enter 提交

The system SHALL, on Web only, treat the **Enter** key as submitting the primary natural-language input when the input is in a submittable state, with behavior equivalent to pressing the visible submit control.

#### Scenario: 单行输入按 Enter 提交

- **WHEN** Web 主输入为单行模式且文本非空，用户按下 Enter
- **THEN** 系统必须触发与点击「提交」相同的指令发送（Mock 或真实接口）

#### Scenario: 多行模式下的换行与提交

- **WHEN** 产品采用多行输入且约定 Shift+Enter 换行
- **THEN** Enter 仍必须触发提交，而 Shift+Enter 必须插入换行且不提前提交

### Requirement: 非 Web 端行为不变

The system SHALL NOT change mobile press-to-talk submission semantics beyond what this change explicitly adds.

#### Scenario: 移动端不受影响

- **WHEN** 用户在 Android 或 iOS 上使用语音主输入
- **THEN** Enter 键行为不得破坏既有按住说话流程
