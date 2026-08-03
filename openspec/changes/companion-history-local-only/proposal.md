## Why

陪伴列表当前会把 Clinic WS `session_sync` 的服务端 turns 合并进 UI，冲掉或重排本机 tip、时间戳与本地顺序。产品要求**历史展示仅为前端**：只展示本机缓存与本会话产生的消息，**忽略** `session_sync` 对列表的重建。

## What Changes

- **BREAKING（展示）**：收到 `session_sync` 时 **不得** 用服务端 `turns` 清空/重建陪伴 `_items`（忽略展示合并）。
- 列表来源仅限：本地 `PangbaoClinicSessionStore` hydrate、本机发送与流式帧、tip 注入、清理记录。
- 实时帧（`thinking_delta` / `answer_delta` / `answer_done` / error / cancel）**保留**（对话能力不变）。
- 可为 `session_sync` 保留 debug 日志；不依赖服务端 turns 做 UI。
- 与基线/既有 change 中「session_sync 权威 merge / 截断 divider」展示条款冲突处，以本变更覆盖。

## Capabilities

### New Capabilities

- `companion-history-local-only`：陪伴历史展示仅前端本地，忽略 session_sync 合并。

### Modified Capabilities

-（展示语义以本能力为准；实现时对照并废止 smart-companion / v2.0.3 中「非空 session_sync 重建列表」的客户端展示义务。）

## Impact

- 代码：`pangbao_ai_screen.dart` 中 `session_sync` 分支与 `_applySessionSync`（可空实现或删除调用）。
- 换机/重装无云端陪伴史；清本地即无历史。
- 不改 Android 原生；后端可仍推 `session_sync`。
