## Context

陪伴 `_ChatItem` 与 `PangbaoClinicTurn` 无时间字段。产品要每条消息上方小字时间；本机打点 + 本地持久化；同日 `HH:mm`、跨日带日期；不合并。

## Goals / Non-Goals

**Goals:**

- `_ChatItem.at`（可空）；用户/助手/tip 赋值；UI 上方小字。
- Store JSON 读写 `at`（ISO8601）；旧数据无字段则不显示时间。
- tip 注入与发送/完成路径打点。

**Non-Goals:**

- 服务端权威时钟或 API 改造。
- 按日分组大标题、同分钟合并。
- 修复 tip 注入可靠性（另案）。

## Decisions

### 1. 打点时机

| 条目 | `at` |
|------|------|
| 用户消息 | `_send` 创建用户气泡时 `DateTime.now()` |
| 助手 | 创建助手气泡时先写 now；`answer_done` 可刷新为完成时刻（二选一：创建时即可，简单） |
| tip | 注入 `setState` 时 now |
| divider | null |

**决策**：助手用**创建气泡时刻**（开始回答），实现简单；不强制 done 改写。

### 2. 格式

- 本地时区；同日历日：`HH:mm`（补零）。
- 否则：`M月d日 HH:mm`（年不同时加 `yyyy年`，可选；默认同年不写年）。

### 3. 持久化

- `PangbaoClinicTurn` 增 `DateTime? at`；tip/qa 序列化；divider 无。
- QA 轮次：用户与助手可同用一轮的 `at` 或分别存——当前 turn 是一对 question/answer。  
  **决策**：store 层 QA 只存一个 `at`（提问时刻）；hydrate 时用户与助手气泡都用该 `at`（或助手 +1s 可选，不强制）。tip 存自己的 `at`。  
  内存里用户/助手仍可各有 `at`（发送与创建时分别 now）。

### 4. UI

- `_buildItem`：非 divider 且 `at != null` 时，气泡上居中/对齐侧小字。
- 低对比 `onSurface` alpha ~0.45，字号 11。

## Risks / Trade-offs

- [旧会话无时间] → 不显示小字，可接受。  
- [QA 只存一个 at] → 用户/助手显示相同或接近时间，可接受。  
- [服务端 merge 新轮次无 at] → 不显示；本机新消息有 at。

## Migration Plan

1. 扩 store + ChatItem。  
2. 打点与 format。  
3. UI。  
4. 手工：发消息、tip 注入、杀进程恢复。

## Open Questions

- 无（格式与每条显示已冻结）。
