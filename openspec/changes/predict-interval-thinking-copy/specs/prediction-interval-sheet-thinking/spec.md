## MODIFIED Requirements

### Requirement: Per-card interval sheet SHALL play thinking typewriter after confirm before close

When the user confirms a typical interval on the per-card「大概多久一次」glass sheet, the client MUST NOT dismiss the sheet immediately. The sheet MUST switch in-place to a thinking phase: the title MUST change to the effect of「大概 {selected interval} 一次」(event logo MAY remain), the interval wheel MUST be hidden, and the body MUST reveal a narrative character-by-character at a deliberate pace aligned with the recall-onboarding thinking typewriter (~42ms per character). The narrative MUST acknowledge that the confirmed interval was recorded and that the next occurrence is being estimated from that rhythm; it MUST NOT claim that the client will automatically switch the display rail to algorithm/affinity prediction without entitlement. The narrative MUST end with a separate bold line whose meaning is: for now estimate the next time using the interval the user just provided, and that as more real feeding records accumulate the forecast can become a closer fit to actual rhythm — MUST NOT use wording that implies an automatic conversion to algorithm prediction, and MUST NOT push paid unlock / trial copy in that bold line. The primary footer control MUST be「跳过动画」while characters are still revealing, and MUST become「关闭」after the full narrative (including the bold line) is visible; activating「关闭」MUST dismiss the sheet. Upsert of the `PredictionRecallSeed` MUST occur on confirm (before or atomically with entering thinking), MUST NOT be deferred until dismiss.

当用户在 per-card「大概多久一次」玻璃 Sheet 上确认间隔时，客户端 **不得** 立刻关闭 Sheet。Sheet **必须** 同层切到思考态：标题 **必须** 变为「大概 {所选间隔} 一次」（事件 logo MAY 保留），间隔滚轮 **必须** 隐藏，正文 **必须** 以与量身定做思考打字机相近的节奏（约每字 42ms）逐字展示叙事。叙事 **必须** 确认已记下间隔并按该节奏估算下次；**不得** 声称展示轨会无开通门槛自动切到算法/亲和预测。叙事文末 **必须** 另起一行加粗说明：先按用户刚补充的间隔估下次，喂养记录多了预测会更贴合实际作息；**不得** 使用暗示「自动改成算法预测」的措辞，**不得** 在该加粗行推销付费开通/试用。主按钮在逐字未完成时 **必须** 为「跳过动画」，全文（含加粗行）可见后 **必须** 变为「关闭」；点「关闭」**必须** 关闭 Sheet。`PredictionRecallSeed` 的 upsert **必须** 在点确认时（进入思考前或同时）完成，**不得** 推迟到关闭。

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

#### Scenario: 加粗脚注不暗示自动切算法

- **WHEN** 思考全文已展示
- **THEN** UI MUST 含另起一行的加粗文案，语义为先按刚补充间隔估下次、记录增多后更贴合实际作息
- **AND** 该加粗文案 MUST NOT 声称会自动修改/切换为算法预测
- **AND** 该加粗文案 MUST NOT 含付费开通或立即试用推销

#### Scenario: 主段不承诺无门槛算法展示

- **WHEN** 思考主段逐字内容可见
- **THEN** 主段 MUST NOT 声称当前已自动切换为算法预测展示
- **AND** 主段 MAY 表述按用户节奏推演下次时间
