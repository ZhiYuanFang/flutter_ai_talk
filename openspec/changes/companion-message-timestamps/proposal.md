## Why

陪伴聊天列表无时间线索，用户难以对照「刚注入的 tip / 刚问的话」发生时刻。需要在每条消息上方以小字展示本地消息时间，并随本地会话持久化，冷启动仍可见。

## What Changes

- 用户气泡、助手气泡、tip 注入气泡：上方展示格式化时间小字。
- 截断 divider **不**展示时间。
- 本机打点：用户发送、助手回答完成（或创建助手气泡时）、tip 注入时写入 `DateTime`。
- 本地 `PangbaoClinicTurn`（含 tip）持久化时间；hydrate 还原。
- 格式：同日 `HH:mm`；跨日带日期（如 `M月d日 HH:mm`）；每条独立展示（不合并同分钟）。
- 服务端 session 轮次若无时间：展示时可省略时间小字或显示占位「—」（实现选「有则显示、无则不显示」）。

## Capabilities

### New Capabilities

- `companion-message-time`：陪伴消息时间戳展示与本地持久化。

### Modified Capabilities

-（无强制修改既有 tip-bridge；tip 注入路径须带时间属本能力场景。）

## Impact

- 代码：`pangbao_ai_screen.dart`（`_ChatItem` / `_buildItem`）、`pangbao_clinic_session_store.dart`。
- 不改 tip SSE、不改 Android 原生；不依赖服务端新字段（有则更好）。
