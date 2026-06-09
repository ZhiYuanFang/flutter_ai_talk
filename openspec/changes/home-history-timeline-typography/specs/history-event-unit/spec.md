## ADDED Requirements

### Requirement: 事件主档与历史行 MUST 持久化单位字段

The system SHALL store optional measurement units on `event.unit` and denormalized `history.event_unit` at write time. List and WebSocket history payloads MUST expose `eventUnit` (camelCase). 系统必须在事件主档与历史行持久化可选单位；列表与 WS 推送 MUST 返回 `eventUnit`。

#### Scenario: 客户端 add 不传 eventUnit 时服务端反规范化

- **WHEN** Flutter 调用 `POST /device/history/api/event/add` 且 body 不含 `eventUnit`，且对应 `eventId` 主档 `unit=ml`
- **THEN** 新 history 行 `event_unit` SHALL 为 `ml`，且 list/WS 响应 `eventUnit` SHALL 为 `ml`

#### Scenario: 事件 options 含 unit

- **WHEN** 客户端请求 `GET /device/history/api/event/options`
- **THEN** 每条事件 JSON MUST 含 `unit` 字段（无单位时为空串或省略）
