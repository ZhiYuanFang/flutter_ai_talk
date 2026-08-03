## ADDED Requirements

### Requirement: Event grid MUST disable while add HTTP in flight

While a button-path history add request is in flight, the home button-mode event grid (and number-event confirm actions that call the same add path) MUST be non-interactive for starting another add. 按钮路径历史添加 HTTP 进行中时，主页按钮模式事件网格（及调用同一添加路径的 number 确认）**必须**不可再发起另一次添加。

#### Scenario: 添加进行中网格不可点

- **WHEN** 用户已触发一次按钮添加且 HTTP 尚未返回
- **THEN** 事件网格（或等价入口）MUST 处于禁用或忽略点击状态，直至该次请求结束
