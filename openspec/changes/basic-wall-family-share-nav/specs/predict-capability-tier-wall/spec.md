## MODIFIED Requirements

### Requirement: Basic-tier capability rows SHALL dismiss the wall then navigate or trigger in-page actions

On the 基础版 slide, each capability **row**（title/subtitle/demo chrome）MUST be tappable. On tap the client MUST first dismiss the capability wall, then MUST perform the action for that row’s kind as follows: `nextEstimate` dismiss only; `pushRemind` open `/settings/notifications`; `homeWidget` open `/widgets/showcase`; `familyShare` open `/settings/baby-share`（邀请家人）；`landscapeCast` MUST present the same「进入投屏模式」confirm used by the prediction-page cast control and on confirm MUST lock landscape cast; `voiceBall` MUST reveal the prediction voice ball to **edge-engaged full circle while still edge-docked**（MUST NOT float to free center solely for this action; MUST NOT auto-start listening via pull-business）; `trendChart` open `/trends`; speaker/`xiaozhiSpeaker` open `/settings/xiaozhi-speaker`. The illustrative demo widgets MAY remain non-interactive（e.g. `IgnorePointer`）so that taps hit the row; tapping the demo alone MUST NOT perform a different business action than the row.

基础版能力行 MUST 可点：先关墙再按 kind 落地（估算仅关墙；推送→通知设置；小组件→showcase；家庭共享→邀请家人 `/settings/baby-share`；投屏→同源确认后锁横屏；语音球→贴边 engaged 全圆且不自动听写；趋势→/trends；音箱→小智设置）。Demo MAY IgnorePointer；MUST NOT 与行动作不一致。

#### Scenario: 推送提醒进通知设置

- **WHEN** 用户点按「智能推送提醒」行
- **THEN** 能力墙 MUST 关闭
- **AND** 客户端 MUST 打开 `/settings/notifications`

#### Scenario: 家庭共享进邀请家人

- **WHEN** 用户点按「家庭全员共享」行
- **THEN** 能力墙 MUST 关闭
- **AND** 客户端 MUST 打开 `/settings/baby-share`

#### Scenario: 投屏走确认

- **WHEN** 用户点按「横向投屏共享」行并在确认框选择「已投屏」
- **THEN** 能力墙 MUST 已关闭
- **AND** 客户端 MUST 进入与预测页投屏按钮相同的横屏投屏锁定流程

#### Scenario: 语音球贴边全圆

- **WHEN** 用户点按「语音球唤醒」行且当时语音球为边缘 peek
- **THEN** 能力墙 MUST 关闭
- **AND** 语音球 MUST 变为贴边 engaged 全圆（仍贴边）
- **AND** MUST NOT 仅因此自动开始听写会话

#### Scenario: 音箱进设置

- **WHEN** 用户点按「家中音箱 · 免动手」行
- **THEN** 能力墙 MUST 关闭
- **AND** 客户端 MUST 打开 `/settings/xiaozhi-speaker`
