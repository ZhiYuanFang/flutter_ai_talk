## 1. 喂养分析预检文案

- [x] 1.1 `CareAlertRepository.analyzeStream`：HTTP 非 200，或 `Content-Type` 为 JSON，或尚未出现 SSE 帧且 body 为 `code != 0` 的 envelope 时，把非空 `message` 交给 `CareAlertStreamErrorEvent`
- [x] 1.2 确认 `text/event-stream` 的 thinking / result 解析不变

## 2. 成长轨迹预检文案

- [x] 2.1 `GrowthTrajectoryRepository.turnStream`：同一类预检 envelope 抛 `ApiBusinessException`（或等价 error 事件），让现有 Toast 使用服务端 `message`
- [x] 2.2 确认 turn 的 thinking / question / result 解析不变

## 3. 校验

- [x] 3.1 `openspec validate sse-preflight-server-message --strict` 通过
