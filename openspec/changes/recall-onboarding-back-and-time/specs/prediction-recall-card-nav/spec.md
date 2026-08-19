## ADDED Requirements

### Requirement: Recall onboarding SHALL offer previous-card back with per-root drafts

On event cards after the first, while the thinking overlay is not showing and the current page is not the finale, the client MUST show a bottom-left control labeled to the effect of「上一步」. Activating it MUST navigate programmatically to the previous root card’s **form** (MUST NOT replay that card’s thinking overlay) and MUST restore that root’s in-session draft for last-occurrence time and interval. The first event card, the thinking overlay, and the finale page MUST NOT show「上一步」. Changing pages MUST NOT reset an already captured draft for a root back to the card’s first-visit defaults.

量身定做在非首张事件卡、且非思考盖层、且非收尾页时，**必须**在左下展示「上一步」；点按 **必须**程序回到上一张**表单**（**不得**重播该卡思考）并恢复该根会话内草稿。第一张事件卡、思考播放中、收尾页 **不得**展示上一步。切页 **不得**把已有草稿打回该根首次默认值。

#### Scenario: 第二张卡上一步回到上一张表单

- **WHEN** 用户在第 2 张或之后的事件卡表单上点「上一步」
- **THEN** 客户端 MUST 回到上一根事件的表单页
- **AND** MUST 恢复该根已填的上次时间与间隔
- **AND** MUST NOT 自动播放上一张的思考盖层

#### Scenario: 第一张卡无上一步

- **WHEN** 当前为队列中第一张事件卡的表单
- **THEN** UI MUST NOT 展示「上一步」

#### Scenario: 思考中与收尾无上一步

- **WHEN** 正在播放思考盖层，或当前为收尾页
- **THEN** UI MUST NOT 展示「上一步」

### Requirement: Recall skip SHALL sit on the event-name row

While an event card form is visible (thinking overlay not showing), the client MUST show a skip control on the same row as the root event name, trailing on the right, labeled exactly「跳过」(MUST NOT keep the long copy「不记得了，跳过」in the bottom-left). Skip semantics remain: disable forecast for that root, do not play long thinking, advance to the next card or finale.

事件卡表单可见（非思考盖层）时，客户端 **必须**在根事件名同一行右侧展示文案恰为「跳过」的控件，**不得**再把「不记得了，跳过」放在左下。跳过语义仍为：关闭该根推演、不播长思考、进入下一卡或收尾。

#### Scenario: 跳过与事件名同行

- **WHEN** 渲染某一根事件的量身定做表单卡
- **THEN** 「跳过」MUST 与事件名同一行且位于右侧
- **AND** 底栏左侧 MUST NOT 再使用「不记得了，跳过」文案

### Requirement: Confirm SHALL re-enable forecast for that root

When the user successfully confirms a recall card (draft accepted and seed written), the client MUST set that root’s forecast enabled (same persistence as the prediction forecast toggle), even if the user had previously skipped the same root in this session.

用户成功确认一卡（草稿被接受并写入种子）时，客户端 **必须**将该根推演设为开启（与预测推演开关同一持久化），即使本会话曾跳过该根。

#### Scenario: 先跳过再确认恢复推演

- **WHEN** 用户对根事件 A 先跳过，再经上一步回到 A 并成功确认
- **THEN** A 的推演 MUST 为开启（持久化）
- **AND** A 的回忆种子 MUST 已写入

### Requirement: Unmodified recall form SHALL block confirm with a hint

When the user activates「确认」on an event card, the client MUST compare the current last-occurrence time (to the minute) and interval with that root’s first-visit default snapshot. If neither value differs, the client MUST NOT write a seed, MUST NOT play thinking, and MUST show small red hint copy exactly「请认真回忆事件」above the confirm button. After the user changes time or interval away from that snapshot, the hint MUST be cleared and a subsequent confirm MAY proceed (subject to existing interval minimum rules).

用户点「确认」时，客户端 **必须**把当前上次时刻（到分钟）与间隔对照该根首次进入时的默认快照；若两者都未改变，**不得**写种子、**不得**播思考，并 **必须**在确认按钮上方以小红字展示「请认真回忆事件」。时间或间隔相对快照改变后 **必须**清除该提示，之后的确认 **可**继续（仍受既有最短间隔约束）。

#### Scenario: 未改默认则拦截并提示

- **WHEN** 用户未改上次时间与间隔（仍为该根首次默认）并点确认
- **THEN** 客户端 MUST NOT 写入回忆种子
- **AND** MUST NOT 进入思考盖层
- **AND** UI MUST 在确认按钮上方展示「请认真回忆事件」

#### Scenario: 改过后确认可通过

- **WHEN** 用户已将上次时间或间隔改为与首次默认不同的值并点确认
- **THEN** 客户端 MUST NOT 仅因「请认真回忆事件」拦截
- **AND** MUST 按既有规则写种子并进入思考（间隔过短等既有错误仍可拦截）
