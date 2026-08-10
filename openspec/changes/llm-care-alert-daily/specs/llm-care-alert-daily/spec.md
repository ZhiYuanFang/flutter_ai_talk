## ADDED Requirements

### Requirement: Client SHALL fetch care-alert list via baby-day server cache

The client SHALL obtain「值得留意」items only from the authenticated daily care-alert API keyed by baby `deviceNo` and calendar day in `Asia/Shanghai`. Same-day successful GETs MUST present the server-cached list without requiring a client-side re-generation. The first fetch for a baby-day MUST wait for server generation (client single-flight). The client MUST NOT evaluate a local rule engine as a source or fallback for this list.

客户端 **必须** 仅从按宝宝 `deviceNo` + 上海自然日的日缓存 API 获取留意列表；同日成功 GET **必须** 使用服务端缓存结果；首次拉取 **必须** 等待服务端生成（客户端 single-flight）；**不得** 以本地规则引擎作为来源或回退。

#### Scenario: 同日二次进入不本地重算

- **WHEN** 同一 `deviceNo` 在同一上海自然日已成功拉取过列表
- **THEN** 客户端再次 ensure 时 MUST 走同一日 API（或会话内成功缓存）且 MUST NOT 运行本地规则引擎

#### Scenario: 首次拉取 single-flight

- **WHEN** 预测页并发触发两次日拉取且当日尚无成功结果
- **THEN** 客户端 MUST 合并为单次 in-flight GET
- **AND** 在完成前 MUST 展示加载态文案（非跑马灯条目）

### Requirement: Care-alert card MUST stay visible with loading, empty, and error states

The client MUST always render the「值得留意」card on the smart prediction page while that page is shown. While the daily fetch is in progress (or not yet ready), the card body MUST show「加载中…」and MUST NOT open detail. When the fetch has failed, the card body MUST show「接口异常」and MUST provide a refresh control that retries the daily fetch with force; the client MUST NOT fall back to a local rule engine. When the fetch succeeds and the client-filtered list is empty (including after all items ignored), the card MUST NOT show the「值得留意」title, the body MUST show「宝宝成长得真棒！」, and activating the card MUST open companion（树洞）and MUST NOT open care-alert detail. When the filtered list is non-empty, the card MUST show the「值得留意」title and the marquee of items.

智能预测页展示期间客户端 **必须** 始终渲染该卡片区；加载中正文 **必须** 为「加载中…」且 **不得** 进详情；失败正文 **必须** 为「接口异常」并提供强制重试刷新，**不得** 回退本地规则；成功且过滤后为空时 **必须不** 显示「值得留意」标题，正文 **必须** 为「宝宝成长得真棒！」，点击 **必须** 进入陪伴/树洞且 **不得** 打开留意详情；非空时 **必须** 显示标题与跑马灯。

#### Scenario: 加载中

- **WHEN** 日拉取尚未完成
- **THEN** 页面 MUST 显示值得留意卡片
- **AND** 正文 MUST 为「加载中…」

#### Scenario: 失败可刷新且无本地回退

- **WHEN** 日拉取 HTTP/业务失败
- **THEN** 正文 MUST 为「接口异常」
- **AND** MUST 提供刷新控件以 force 重试
- **AND** MUST NOT 回退本地规则引擎结果

#### Scenario: 成功空列表

- **WHEN** 日拉取成功且过滤后列表为空
- **THEN** 卡片 MUST NOT 显示标题「值得留意」
- **AND** 正文 MUST 为「宝宝成长得真棒！」
- **AND** 点击卡片 MUST 打开陪伴/树洞
- **AND** MUST NOT 打开留意详情

### Requirement: Each item MUST carry day-scoped suggestionId

Every displayed care-alert item MUST include a server-generated `suggestionId` (UUID) that is scoped to that baby-day cache. Client ignore/follow-up actions MUST address items by this `suggestionId`.

每条展示项 **必须** 含服务端生成的当日作用域 `suggestionId`；忽略/追问 **必须** 用该 id 定位。

#### Scenario: 详情动作带 suggestionId

- **WHEN** 用户打开某条留意详情
- **THEN** 该项 MUST 具备非空 `suggestionId`
- **AND** 忽略/追问请求 MUST 携带该 `suggestionId`

### Requirement: Ignore MUST remove only that day’s cache item

When the user ignores one suggestion, the client MUST (1) remove it locally from the current list, (2) leave the detail route, (3) call Go to delete that `suggestionId` from the baby-day cache, and (4) post flywheel feedback with fixed intent `ignore`. Ignore MUST NOT permanently suppress the event across future days. After the last item is ignored, the list MUST be empty and the card MUST show the empty-state copy「宝宝成长得真棒！」(MUST NOT hide the card).

忽略一条时客户端 **必须** 本地移除、退出详情、请求 Go 删当日缓存项，并以固定意图 `ignore` 上报飞轮；**不得** 跨日永久压制；全部忽略后列表 **必须** 为空且卡片 **必须** 展示「宝宝成长得真棒！」（**不得** 隐藏卡片）。

#### Scenario: 忽略单条

- **WHEN** 用户在详情点击忽略且当前列表有多项
- **THEN** 客户端 MUST 立刻不再展示该 `suggestionId`
- **AND** MUST 调用删除当日缓存项 API
- **AND** MUST 以 intent=`ignore` 上报飞轮
- **AND** 其余项 MUST 仍可展示

#### Scenario: 全部忽略后空态

- **WHEN** 用户忽略最后一条
- **THEN** 卡片区 MUST 仍显示且 MUST NOT 显示标题「值得留意」
- **AND** 正文 MUST 为「宝宝成长得真棒！」
- **AND** 点击 MUST 打开陪伴/树洞

### Requirement: Follow-up MUST open companion with API followUpPrompt

When the user chooses follow-up（追问）, the client MUST post flywheel feedback with fixed intent `follow_up` and MUST open companion（树洞）passing the item’s `followUpPrompt` as-is for input/send prefill. The client MUST NOT rewrite or NLP-interpret the prompt text.

追问时客户端 **必须** 以 intent=`follow_up` 上报飞轮，并打开树洞、将 API 的 `followUpPrompt` 原样用于预填/发送；**不得** 改写或对文案做 NLP。

#### Scenario: 追问预填

- **WHEN** 用户在详情点击追问且 `followUpPrompt` 非空
- **THEN** 客户端 MUST 导航至陪伴/树洞
- **AND** MUST 将该 `followUpPrompt` 原样作为预填或自动发送文案
- **AND** MUST 以 intent=`follow_up` 上报飞轮

### Requirement: Flywheel feedback MUST use fixed intents only

Care-alert feedback HTTP MUST send only enumerated intents (`ignore` / `follow_up`) plus identifiers (`deviceNo`, `suggestionId`). The client MUST NOT send free-form feedback text for NLP classification on this path.

飞轮反馈 **必须** 仅使用固定意图枚举与标识字段；**不得** 在此路径发送供 NLP 分类的自由文本。

#### Scenario: 无 NLP 文本

- **WHEN** 用户忽略或追问
- **THEN** feedback 请求 body MUST 含 `intent` 为 `ignore` 或 `follow_up`
- **AND** MUST NOT 依赖对用户自由输入的 NLP 分类

### Requirement: Forecast-off filtering SHALL remain client-side

After a successful server list is available, the client MUST exclude items whose `eventId` is in the local forecast-disabled set before presenting the marquee. VIP/model selection MUST NOT be performed by the Flutter client for generation; Go selects DeepSeek vs Zhipu.

服务端列表成功后，客户端 **必须** 再按本地推演关闭集合过滤；生成用模型 **不得** 由 Flutter 选择（Go 选 DeepSeek/Zhipu）。

#### Scenario: 推演关闭过滤

- **WHEN** 服务端返回事件 A 与 B，且用户关闭了 A 的推演
- **THEN** 跑马灯 MUST NOT 展示 A
- **AND** 若仅剩被关闭项则整块 MUST 隐藏
