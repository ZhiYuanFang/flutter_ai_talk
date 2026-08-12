## ADDED Requirements

### Requirement: 预测页落库飞入 MUST NOT 依赖喂养页曾挂载

When the home shell history WebSocket session is active and the visible pager page is prediction, a History WebSocket create/update that the product treats as fly-worthy MUST be able to request the shared fly overlay without the feeding `HomeScreen` ever having been mounted in this process. 当主壳历史 WS 会话已激活且可见页为预测时，对产品认定为可飞入的 History WS create/update，MUST 能请求共享飞入 Overlay，且 MUST NOT 要求本次进程内喂养页 `HomeScreen` 曾挂载。

#### Scenario: 冷启动仅预测页加事件可飞

- **WHEN** 已登录用户冷启动后仅停留在预测页（未进喂养）
- **AND** 主壳已完成历史 WS 订阅与建连
- **AND** 用户在预测页完成一次导致 History WS 推送的加/改事件
- **THEN** 客户端 MUST 发出预测向 `HistoryEventFlyRequest`（动画开关未禁用时）
- **AND** MUST NOT 因喂养页未 mount 而跳过请求
