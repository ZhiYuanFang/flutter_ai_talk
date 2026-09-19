## ADDED Requirements

### Requirement: Growth trajectory preflight envelope SHALL toast the server message

When a growth-trajectory turn is rejected before SSE starts and the response is an HTTP 200 JSON business envelope with `code != 0` (including daily-limit code 40303), or a non-200 response whose body is that envelope, the client MUST toast the envelope `message` when it is non-empty. The client MUST NOT replace that message with a generic local failure string such as「成长轨迹预测失败」or「成长轨迹预测暂时不可用，请稍后再试」. A real `text/event-stream` body MUST still be parsed as thinking, question, and result events. 成长轨迹 turn 在开流前被拒绝且响应为 `code != 0` 的业务 envelope 时，客户端 **必须** Toast 非空 `message`，**不得** 换成本地通用失败文案；真正的 SSE **必须** 仍按 thinking / question / result 解析。

#### Scenario: 日限 envelope 展示服务端文案

- **WHEN** 用户发起轨迹预测且服务端因当日次数用尽返回 HTTP 200 与非空 `message`（例如「今日成长轨迹预测次数已用完，请明日再来」）
- **THEN** 客户端 MUST Toast 该 `message`
- **AND** MUST NOT Toast「成长轨迹预测暂时不可用，请稍后再试」

#### Scenario: 真正的 turn 流不被当成 envelope

- **WHEN** turn 接口返回 `text/event-stream`
- **THEN** 客户端 MUST 继续按 thinking、question、result 更新界面
- **AND** MUST NOT 把正常 SSE 判成预检失败
