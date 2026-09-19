## ADDED Requirements

### Requirement: Feeding analysis SHALL show a long-wait hint while thinking

While a manual feeding-record analysis is in flight, the feeding analysis workspace SHALL show a static hint that analysis is being prepared for this child, that it takes a while, and that the user may leave and return later to see the result. The hint MUST remain visible for the whole in-flight period. The hint MUST NOT be written into the streaming thinking text consumed by `AiThinkingPane`. 喂养分析进行中，工作台 **必须** 展示静态等待说明（为宝宝针对性分析、用时较久、可先离开再回来看结果）；该说明 **必须** 在整个进行中保持可见，且 **不得** 写入思考流正文。

#### Scenario: 思考中可见等待说明

- **WHEN** 用户已点击「AI智能分析」且该次生成尚未结束
- **THEN** 页面 MUST 在思考区之外展示等待说明
- **AND** 思考流增量 MUST NOT 清除或替换该说明

#### Scenario: 未在分析时不展示该说明

- **WHEN** 喂养工作台处于历史列表、空态或未开始分析
- **THEN** 页面 MUST NOT 展示上述等待说明

### Requirement: Re-entering feeding analysis SHALL keep an in-flight run

If a feeding-record analysis request is still in flight, entering the feeding analysis workspace again MUST NOT replace that in-flight state with the cached latest list. The workspace MUST continue to show the thinking area and the long-wait hint. Fetching latest without force MUST remain allowed only when no analysis is in flight. 分析请求尚未结束时再次进入喂养工作台，**不得** 用历史 latest 覆盖进行中状态；**必须** 继续展示思考区与等待说明。仅在没有进行中分析时才允许无 force 的 latest 拉取覆盖列表。

#### Scenario: 退出再进仍为思考中

- **WHEN** 用户在分析尚未结束时离开喂养工作台，并在同一次 App 进程内再次进入
- **THEN** 正文 MUST 仍为思考中（含等待说明）
- **AND** MUST NOT 把正文换成上一次已落库的历史列表

#### Scenario: 没有进行中分析时仍拉历史

- **WHEN** 用户进入喂养工作台且当前没有进行中的分析请求
- **THEN** 客户端 MAY 拉取不扣次数的 latest 并展示历史记录

### Requirement: Repeat analyze tap SHALL say the previous run is still in progress

When the user taps 「AI智能分析」 while a feeding-record analysis is already in flight, the client MUST show a toast that the previous analysis is still in progress, and MUST NOT start another generate request. The analyze control MUST remain activatable during that in-flight period so the toast can be shown. The client MUST NOT wait for the in-flight request to finish before showing this toast. 进行中再次点击「AI智能分析」时，客户端 **必须** 立刻 Toast 上一次仍在分析，**不得** 再发起一次生成，也 **不得** 等到上一次请求结束后才提示。进行中该按钮 **必须** 仍可点。

#### Scenario: 再点立刻提示且不发第二次请求

- **WHEN** 一次喂养分析尚未结束，用户再次点击「AI智能分析」
- **THEN** 客户端 MUST Toast 上一次分析还在进行
- **AND** MUST NOT 再调用 care-alert 生成接口
- **AND** Toast MUST 在本次点击后立即出现，而不是等上一次请求返回
