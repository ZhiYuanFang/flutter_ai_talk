## ADDED Requirements

### Requirement: Feeding analysis preflight envelope SHALL toast the server message

When manual feeding analysis calls the care-alert generate stream and the response is an HTTP 200 JSON business envelope with `code != 0` (including daily-limit code 40304), or a non-200 response whose body is that envelope, the client MUST toast the envelope `message` when it is non-empty. The client MUST NOT replace that message with「分析失败，请稍后重试」or an equivalent generic failure string. A real `text/event-stream` body MUST still be parsed as thinking and result events. 喂养分析生成流若收到 HTTP 200（或非 200）的业务 envelope 且 `code != 0`，客户端 **必须** Toast 非空 `message`，**不得** 换成「分析失败，请稍后重试」；真正的 SSE **必须** 仍按思考与结果事件解析。

#### Scenario: 日限 envelope 展示服务端文案

- **WHEN** 用户点击「AI智能分析」且服务端因当日次数用尽返回 HTTP 200 与 `message` 为「今日值得留意分析次数已用完，请明日再来」（或其它非空日限文案）
- **THEN** 客户端 MUST Toast 该 `message`
- **AND** MUST NOT Toast「分析失败，请稍后重试」
- **AND** MUST NOT 把该 JSON 当作空 SSE 结束后再套通用失败文案

#### Scenario: 真正的思考流不被当成 envelope

- **WHEN** 生成接口返回 `text/event-stream` 且推送 thinking 或 result
- **THEN** 客户端 MUST 继续展示思考流并在 result 时更新列表
- **AND** MUST NOT 仅因某一 data 行是 JSON 就中止为业务失败
