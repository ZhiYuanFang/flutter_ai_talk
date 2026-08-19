## MODIFIED Requirements

### Requirement: Each recall card SHALL collect last time interval and leaf by controls only

Each card SHALL let the user select: (1) last occurrence time to the minute via the glass last-time picker（for `time` event types, the prompt MUST mean last **end** time）; (2) typical interval via wheel with minimum at least 15 minutes. Child events, when shown, MUST follow the read-only containment rules of `prediction-recall-card-ux` (MUST NOT collect a selected leaf via buttons). The card MUST offer skip on the event-name row as specified by `prediction-recall-card-nav`. The UI MUST NOT require free-text keyboard input for these fields.

每卡 **必须** 用滚轮/玻璃选择器采集上次时刻（到分钟；`time` 型为上次结束）与间隔（≥15 分钟）；子事件展示 **必须** 遵循 `prediction-recall-card-ux` 只读包含规则（**不得** 再用按钮采集叶子）。卡片 **必须** 按 `prediction-recall-card-nav` 在事件名行提供跳过。**不得** 要求键盘手输上述字段。

#### Scenario: 禁止手输

- **WHEN** 用户在回忆卡上操作
- **THEN** UI MUST NOT 出现用于填写上次时间/间隔/叶子的文本输入框

#### Scenario: 不再用按钮选叶子

- **WHEN** 当前根有或没有子事件
- **THEN** 卡片 MUST NOT 要求用户用按钮/Chip 选中某个叶子才能确认

### Requirement: Skip SHALL disable forecast for that root without long thinking

When the user skips a card via the title-row「跳过」control, the client MUST disable forecast for that root event (same persistence as prediction forecast toggle), MUST NOT play the long per-card thinking typewriter for that skip, and MUST advance to the next queue item (or finale if none remain).

用户通过标题行「跳过」跳过卡时，客户端 **必须** 关闭该根推演、**不得** 播放该卡长思考逐字动画，并 **必须** 进入下一队列项或收尾。

#### Scenario: 跳过关推演

- **WHEN** 用户在根事件 A 的卡片上选择跳过
- **THEN** A 的推演 MUST 被关闭（持久化）
- **AND** MUST NOT 播放结合 A 填写内容的长思考逐字
- **AND** 引导 MUST 进入下一缺口卡或收尾
