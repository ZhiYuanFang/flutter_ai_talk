## ADDED Requirements

### Requirement: 思考态弹幕 MUST 使用更浅的主题字色

While the landscape voice subtitle displays server thinking content, the toast text color MUST use a muted on-panel-glass semantic color (`AppColor.textOnPanelGlassMuted` or documented equivalent), and MUST NOT use the same full-contrast on-panel color as the final answer subtitle. 当横屏语音弹幕展示服务端思考内容时，toast 字色 MUST 使用更浅的 on-panel-glass 语义色（`AppColor.textOnPanelGlassMuted` 或已文档化等价），MUST NOT 与最终答案弹幕使用同一满对比 on-panel 色。

#### Scenario: 思考增量展示为浅字

- **WHEN** 客户端正在展示 `thinking_delta` 累积后的思考字幕
- **THEN** 弹幕文字 MUST 使用 muted 语义字色
- **AND** MUST 仍经 `AppColor` 取色（禁止业务硬编码灰 hex）

#### Scenario: 答案恢复满对比

- **WHEN** 服务端 `answer` 写入弹幕
- **THEN** 弹幕文字 MUST 使用满对比 on-panel 字色（非 thinking muted）

### Requirement: 思考态弹幕 MUST 施加慢而弱的 opacity 脉冲

While the subtitle is in the thinking role, the toast MUST apply a slow, low-amplitude repeating opacity pulse so the user can perceive ongoing thinking. The pulse MUST stop when the subtitle leaves the thinking role (answer, ASR prompt, or clear). 当弹幕处于思考角色时，toast MUST 施加慢、弱幅度的循环 opacity 脉冲，使用户可感知仍在思考；当弹幕离开思考角色（答案、ASR/提示或清空）时，脉冲 MUST 停止。

#### Scenario: 进入思考开始脉冲

- **WHEN** 弹幕角色切换为 thinking 且字幕非空
- **THEN** MUST 开始慢周期、弱幅度的 opacity 脉冲（建议周期约 1.2–1.8s，opacity 下限不宜过低以免不可读）

#### Scenario: 答案到达停止脉冲

- **WHEN** 弹幕切换为 answer（或非 thinking）
- **THEN** MUST 停止脉冲并将 opacity 恢复为稳定可见值

### Requirement: 控制器 MUST 显式暴露弹幕是否为思考态

The landscape voice UI state MUST expose an explicit signal that the current subtitle is thinking content (enum kind or boolean), updated on thinking deltas and cleared/replaced on answer, ASR-driven subtitles, and subtitle clear. The toast MUST NOT infer thinking solely by string-equality heuristics. 横屏语音 UI 状态 MUST 显式暴露「当前字幕是否为思考」（枚举或布尔），在 thinking 增量时置位，在 answer、ASR 驱动字幕与清空时清除/改写；toast MUST NOT 仅靠字符串相等启发式推断思考态。

#### Scenario: thinking_delta 置位

- **WHEN** 处理 `VoiceChatThinkingDelta` 并更新字幕
- **THEN** 状态 MUST 将弹幕标记为 thinking

#### Scenario: answer 改写标记

- **WHEN** 处理 `VoiceChatAnswer` 并更新字幕
- **THEN** 状态 MUST 将弹幕标记为非 thinking（answer）
