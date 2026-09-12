## ADDED Requirements

### Requirement: Per-card interval sheet SHALL play thinking typewriter after confirm before close

When the user confirms a typical interval on the per-card「大概多久一次」glass sheet, the client MUST NOT dismiss the sheet immediately. The sheet MUST switch in-place to a thinking phase: the title MUST change to the effect of「大概 {selected interval} 一次」(event logo MAY remain), the interval wheel MUST be hidden, and the body MUST reveal a smart-analysis narrative character-by-character at a deliberate pace aligned with the recall-onboarding thinking typewriter (~42ms per character). The narrative MUST end with a separate bold line stating that prediction times will auto-adjust as later feeding rhythm accumulates and that the current forecast only adapts when feeding history is still insufficient. The primary footer control MUST be「跳过动画」while characters are still revealing, and MUST become「关闭」after the full narrative (including the bold line) is visible; activating「关闭」MUST dismiss the sheet. Upsert of the `PredictionRecallSeed` MUST occur when confirm is pressed (before or as thinking starts), not deferred until close.

当用户在 per-card「大概多久一次」玻璃 Sheet 上确认间隔时，客户端 **不得** 立刻关闭 Sheet。Sheet **必须** 同层切到思考态：标题 **必须** 变为「大概 {所选间隔} 一次」（事件 logo MAY 保留），间隔滚轮 **必须** 隐藏，正文 **必须** 以与量身定做思考打字机相近的节奏（约每字 42ms）逐字展示智能分析叙事。叙事文末 **必须** 另起一行加粗说明：后续喂养节奏会自动修改预测时间，当前仅为适应喂养信息仍不足时的推演。主按钮在逐字未完成时 **必须** 为「跳过动画」，全文（含加粗行）可见后 **必须** 变为「关闭」；点「关闭」**必须** 关闭 Sheet。`PredictionRecallSeed` 的 upsert **必须** 在点确认时（进入思考前或同时）完成，**不得** 推迟到关闭。

#### Scenario: 确认后同层思考

- **WHEN** 用户在间隔滚轮 Sheet 点确定且间隔合法
- **THEN** Sheet MUST 保持打开并进入思考态
- **AND** 标题 MUST 反映「大概 {间隔} 一次」
- **AND** 滚轮 MUST 不再展示
- **AND** 客户端 MUST 已 upsert 该根回忆种子（或与切入思考原子完成）

#### Scenario: 跳过动画后关闭

- **WHEN** 思考态逐字未完成
- **THEN** 主按钮 MUST 为「跳过动画」
- **WHEN** 用户点「跳过动画」或打字机播完全文（含加粗说明行）
- **THEN** 主按钮 MUST 变为「关闭」
- **AND** 点「关闭」MUST dismiss Sheet

#### Scenario: 加粗自适应说明

- **WHEN** 思考全文已展示
- **THEN** UI MUST 含另起一行的加粗文案，语义为后续喂养节奏将自动修正预测时间、当前仅为信息不足时的适应

### Requirement: After thinking completes status SHALL show next occurrence and allow re-pick interval

When the thinking typewriter (including the bold footer line) has finished, the sheet status line that previously showed「正在思考…」MUST change to exactly the form「思考完毕 · 下一次{eventName}：{time}发生」, where `{time}` is a human-readable local clock for an estimated next occurrence derived from the confirmed lastAt plus the chosen interval. Activating that status line MUST return the sheet in-place to the interval-picking phase (wheel visible again) so the user can choose a different interval and confirm again. While characters are still revealing, the status MUST remain「正在思考…」and MUST NOT be tappable for re-pick.

当思考打字机（含加粗说明行）播完后，原「正在思考…」状态行 **必须** 变为「思考完毕 · 下一次{事件名}：{时刻}发生」，其中时刻为基于已确认 `lastAt` 与所选间隔估算的下次发生本地可读时间。点按该状态行 **必须** 同层回到间隔选择态（再显滚轮）以便重选并再次确认。逐字未完成时状态 **必须** 仍为「正在思考…」，且 **不得** 作为重选入口可点。

#### Scenario: 播完展示下次时刻

- **WHEN** 思考全文（含加粗行）已可见
- **THEN** 状态行 MUST 为「思考完毕 · 下一次{事件名}：{时刻}发生」
- **AND** MUST NOT 仍显示「正在思考…」

#### Scenario: 点状态行重选间隔

- **WHEN** 用户点按「思考完毕 · …」状态行
- **THEN** Sheet MUST 回到 picking 态并再展示间隔滚轮
- **AND** MUST NOT 因此关闭 Sheet
