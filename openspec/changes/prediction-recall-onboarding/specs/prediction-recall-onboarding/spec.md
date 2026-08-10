## ADDED Requirements

### Requirement: Prediction page SHALL show recall cards for root event gaps

When the user opens the smart prediction page and at least one catalog root event (`parentId == null`) lacks sufficient real-history samples for the local predictor, the client SHALL present an embedded floating-card PageView onboarding (量身定做) instead of only the static empty copy. The queue MUST include every such gapped root and MUST NOT include roots whose real history already meets the predictor sample gate. Roots the user has skipped (forecast disabled) MUST NOT re-enter the queue until forecast is re-enabled.

进入智能预测页且存在根事件真历史不足以支撑本地推演时，客户端 **必须** 展示内嵌悬浮卡 PageView 量身定做引导；队列 **必须** 覆盖全部缺口根，**不得** 包含已达门槛的根；已跳过关推演的根 **不得** 再入队，直至重新开启推演。

#### Scenario: 有缺口则展示引导

- **WHEN** 用户进入智能预测页且至少有一个根事件真历史未达推演样本门槛
- **THEN** UI MUST 展示悬浮卡片式 PageView 引导
- **AND** MUST NOT 仅展示「暂无可用预测数据」而无引导

#### Scenario: 无缺口不展示引导

- **WHEN** 用户进入智能预测页且所有根事件真历史均已达门槛（或无可排队缺口）
- **THEN** UI MUST NOT 展示量身定做卡片队列
- **AND** MUST 按正常预测页逻辑展示

### Requirement: Each recall card SHALL collect last time interval and leaf by controls only

Each card SHALL let the user select: (1) last occurrence time to the minute via wheel（for `time` event types, the prompt MUST mean last **end** time）; (2) typical interval via wheel with minimum at least 15 minutes; (3) leaf event via buttons — if the root has children, buttons are those children; if the root has no children, exactly one button for the root itself. The card MUST offer skip. The UI MUST NOT require free-text keyboard input for these fields.

每卡 **必须** 用滚轮采集上次时刻（到分钟；`time` 型为上次结束）与间隔（≥15 分钟），用按钮采集叶子（无子则仅根自身一钮），并提供跳过；**不得** 要求键盘手输。

#### Scenario: 无子根单钮

- **WHEN** 当前根事件没有子节点
- **THEN** 叶子选择区 MUST 仅展示该根自身一个按钮

#### Scenario: 有子根展示子按钮

- **WHEN** 当前根事件有一个或多个子节点
- **THEN** 叶子选择区 MUST 展示这些子节点按钮（不得要求手输叶子名）

#### Scenario: 禁止手输

- **WHEN** 用户在回忆卡上操作
- **THEN** UI MUST NOT 出现用于填写上次时间/间隔/叶子的文本输入框

### Requirement: Skip SHALL disable forecast for that root without long thinking

When the user skips a card, the client MUST disable forecast for that root event (same persistence as prediction forecast toggle), MUST NOT play the long per-card thinking typewriter for that skip, and MUST advance to the next queue item (or finale if none remain).

跳过卡时客户端 **必须** 关闭该根推演、**不得** 播放该卡长思考逐字动画，并 **必须** 进入下一队列项或收尾。

#### Scenario: 跳过关推演

- **WHEN** 用户在根事件 A 的卡片上选择跳过
- **THEN** A 的推演 MUST 被关闭（持久化）
- **AND** MUST NOT 播放结合 A 填写内容的长思考逐字
- **AND** 引导 MUST 进入下一缺口卡或收尾

### Requirement: Completing a card SHALL play slow typewriter thinking then continue

After the user confirms a filled card, the client MUST play a thinking script that interpolates that card’s selected event name, leaf name, last time, and interval, revealed character-by-character at a deliberately slow pace. After that segment finishes, the client MUST proceed to the next gap card, or to the finale CTA when the queue is empty.

用户确认一卡后，客户端 **必须** 慢速逐字播放插值该卡内容的思考文案，然后进入下一缺口卡；队列空则进入收尾 CTA。

#### Scenario: 逐卡思考

- **WHEN** 用户为根事件 A 确认上次时刻、间隔与叶子
- **THEN** UI MUST 展示包含 A 名称/叶子/时间/间隔信息的逐字思考文案
- **AND** 播放结束后 MUST 进入下一缺口卡或收尾

### Requirement: Finale CTA SHALL reveal normal prediction UI

When the gap queue is exhausted, the client SHALL show a short finale and a primary CTA「体验胖宝智能预测」(or equivalent). Activating the CTA MUST dismiss the onboarding layer and show the normal smart prediction content driven by merged history and seeds. If the user later returns and new root gaps exist, the onboarding MUST be allowed to appear again.

队列耗尽后 **必须** 展示收尾与 CTA；点击后 **必须** 关闭引导并展示正常预测；日后若再出现缺口 **必须** 允许再次引导。

#### Scenario: CTA 进入预测

- **WHEN** 用户完成队列并点击「体验胖宝智能预测」
- **THEN** 量身定做层 MUST 关闭
- **AND** 智能预测页 MUST 展示正常预测内容（含可用种子/历史合并结果）
