## ADDED Requirements

### Requirement: Companion messages MUST show a local timestamp above the bubble when known

When a companion chat item is a user message, assistant message, or tip-sourced assistant message and has a known local timestamp, the client MUST render that time as small secondary text above the message bubble. Divider items MUST NOT show a timestamp. 陪伴列表中用户消息、助手消息或 tip 源助手消息在已知本地时间戳时，客户端 **必须** 在气泡上方以次要小字展示该时间；截断 divider **不得** 展示时间。

#### Scenario: 新发送用户消息显示时间

- **WHEN** 用户成功发出一条陪伴消息
- **THEN** 该用户气泡上方 MUST 显示本地格式化时间小字

#### Scenario: tip 注入显示时间

- **WHEN** 未消费 tip 被注入为助手气泡
- **THEN** 该 tip 气泡上方 MUST 显示注入时刻的本地格式化时间

#### Scenario: divider 无时间

- **WHEN** 列表项为截断 divider
- **THEN** MUST NOT 在该项上方展示时间小字

### Requirement: Companion timestamp format MUST distinguish same-day and other-day

For a message with a known timestamp, the client MUST format same-calendar-day times as `HH:mm` and other-day times with a date component (e.g. `M月d日 HH:mm`) in the device local timezone. 已知时间戳时，客户端 **必须** 对同一日历日格式化为 `HH:mm`，对非当日带日期成分（如 `M月d日 HH:mm`），时区为设备本地。

#### Scenario: 当日仅时分

- **WHEN** 消息 `at` 为今天本地 15:08
- **THEN** 展示 MUST 为 `15:08`（或等价补零时分），MUST NOT 强制带日期

### Requirement: Companion timestamps MUST persist in local session store

Completed turns and tip entries persisted in the local clinic session store MUST retain timestamps when known so that cold start hydration can restore them on chat items. 本地 clinic 会话中已完成轮次与 tip 条目在已知时间时 **必须** 持久化时间戳，冷启动 hydrate **必须** 能还原到聊天气泡。

#### Scenario: 杀进程后仍见时间

- **WHEN** 用户发送消息或注入 tip 后进程被杀再进入陪伴
- **AND** 本地 store 含对应 `at`
- **THEN** 还原的气泡上方 MUST 仍显示该时间

#### Scenario: 旧数据无 at

- **WHEN** 本地条目无时间字段（升级前数据）
- **THEN** 客户端 MUST NOT 伪造时间；MAY 省略时间小字
