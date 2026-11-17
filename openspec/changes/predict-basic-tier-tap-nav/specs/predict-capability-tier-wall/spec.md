## ADDED Requirements

### Requirement: Basic-tier speaker row MUST use benefit-first copy without Xiaozhi brand on the wall

On the 基础版 slide of the predict capability wall, the speaker capability row title MUST be「家中音箱 · 免动手」（or equivalent benefit-first wording without the brand「小智」）. The subtitle MUST describe connecting a physical hardware speaker, using it without holding the phone, and recording/querying baby daily information by voice alone. The mid-fidelity demo paid hint「可付费开通」MAY remain unchanged. The settings screen title MAY continue to say「小智音箱」.

基础版墙音箱条 MUST 用「家中音箱 · 免动手」类利益优先标题且 MUST NOT 在墙标题中使用「小智」；副标题 MUST 说明实体硬件、脱离手机、纯语音记查；demo「可付费开通」MAY 保留；设置页 MAY 仍用品牌名。

#### Scenario: 墙标题无小智品牌

- **WHEN** 用户查看基础版能力列表中的音箱条目
- **THEN** 条目标题 MUST 为「家中音箱 · 免动手」（或同等无「小智」的利益表述）
- **AND** 副标题 MUST 提及实体硬件音箱与脱离手机的纯语音记查

#### Scenario: 设置页品牌可保留

- **WHEN** 用户从该条目进入音箱设置页
- **THEN** 设置页 AppBar 标题 MAY 仍为「小智音箱」

### Requirement: Basic-tier capability rows SHALL dismiss the wall then navigate or trigger in-page actions

On the 基础版 slide, each capability **row**（title/subtitle/demo chrome）MUST be tappable. On tap the client MUST first dismiss the capability wall, then MUST perform the action for that row’s kind as follows: `nextEstimate` dismiss only; `pushRemind` open `/settings/notifications`; `homeWidget` open `/widgets/showcase`; `familyShare` MUST NOT navigate to another route（dismiss only is allowed）; `landscapeCast` MUST present the same「进入投屏模式」confirm used by the prediction-page cast control and on confirm MUST lock landscape cast; `voiceBall` MUST reveal the prediction voice ball to **edge-engaged full circle while still edge-docked**（MUST NOT float to free center solely for this action; MUST NOT auto-start listening via pull-business）; `trendChart` open `/trends`; speaker/`xiaozhiSpeaker` open `/settings/xiaozhi-speaker`. The illustrative demo widgets MAY remain non-interactive（e.g. `IgnorePointer`）so that taps hit the row; tapping the demo alone MUST NOT perform a different business action than the row.

基础版能力行 MUST 可点：先关墙再按 kind 落地（估算仅关墙；推送→通知设置；小组件→showcase；家庭不跳转；投屏→同源确认后锁横屏；语音球→贴边 engaged 全圆且不自动听写；趋势→/trends；音箱→小智设置）。Demo MAY IgnorePointer；MUST NOT 与行动作不一致。

#### Scenario: 推送提醒进通知设置

- **WHEN** 用户点按「智能推送提醒」行
- **THEN** 能力墙 MUST 关闭
- **AND** 客户端 MUST 打开 `/settings/notifications`

#### Scenario: 家庭共享不跳转

- **WHEN** 用户点按「家庭全员共享」行
- **THEN** 客户端 MUST NOT 因此 `push`/`go` 到其它业务路由（关墙即可）

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
