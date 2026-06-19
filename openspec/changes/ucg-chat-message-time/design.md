## Context

- `UcgChatScreen` 通过 `_ChatBubble` 渲染文本/图片/视频气泡，列表为 `reverse: true` 的 `ListView`；`UcgChatMessage.createdAt` 已由 API 或乐观发送写入。
- 喂养模块 `history_line_format.dart` 提供 `formatHistoryInstant(DateTime t, DateTime nowLocal)`，输出今天 `HH:mm`、昨天 `昨天HH:mm`、同年 `M月D日 HH:mm`、跨年 `Y年M月D日 HH:mm`。
- 用户明确要求：**仅聊天窗口**与 `formatHistoryInstant` 一致；会话列表等仍用 `DateFormat('MM-dd HH:mm')`。

## Goals / Non-Goals

**Goals:**

- 每条聊天消息气泡下方展示发送时间小字。
- 时间文案统一调用 `formatHistoryInstant(createdAt.toLocal(), DateTime.now())`。
- 己方/对方、纯文本/纯媒体/图文混排布局一致可辨；时间与气泡同侧对齐。

**Non-Goals:**

- 不改会话列表、互动收件箱、Feed、详情帖时间格式。
- 不引入 `formatHistoryRelativeAgo`（刚刚/分前）。
- 不做「间隔 N 分钟才显示」的 WeChat 式时间条；默认每条消息均显示。
- 不改 `formatHistoryInstant` 实现或抽取新包（直接 import 现有工具）。

## Decisions

### 1. 挂载点：`_ChatBubble` 外包 `Column`

- **选择**：在 `_ChatBubble.build` 各分支返回值外包 `Column(bubble, timeLabel)`，或统一在末尾包装，避免改列表层 Row（头像 + 气泡 + 头像）。
- **理由**：时间语义属于「消息块」而非整行；头像列不受影响。
- **备选**：在 `itemBuilder` Row 内加第三列 — 难对齐多形态气泡，否决。

### 2. 格式化：直接 `formatHistoryInstant`

- **选择**：`import '../../../data/history_line_format.dart'`（按实际相对路径），`formatHistoryInstant(m.createdAt.toLocal(), DateTime.now())`。
- **理由**：与 proposal 及用户决策一致；零新逻辑。
- **备选**：UCG 内再包一层 `formatUcgChatTime` — 仅多一行转发，非必须。

### 3. 样式

- **选择**：`fontSize: 10–11`，颜色 `fg.withValues(alpha: 0.45)`，与 `UcgMessagesTab` 列表时间弱化风格接近；`padding: EdgeInsets.only(top: 4)`。
- **对齐**：对方 `CrossAxisAlignment.start`，己方 `CrossAxisAlignment.end`（与气泡列一致）。

### 4. 己方 pending / failed

- **选择**：时间与 delivered 相同，仍显示 `createdAt`；状态图标保留在气泡右侧，时间在其下方。
- **理由**：`createdAt` 在乐观行已为 `DateTime.now()`，符合「发送时刻」直觉。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 长对话每条都有时间，信息密度偏高 | 用户明确要求每条下方；后续可另开 change 做间隔显示 |
| UCG 依赖 `history_line_format`（含 HistoryRecord 相关模块） | 仅引用纯函数，不引入 UI 耦合；可接受 |
| 历史消息 `createdAt` 为 0 时显示异常 epoch | 依赖 API 正常下发；若遇空值可显示空串（实现时 guard） |

## Migration Plan

1. 改 `_ChatBubble`（或抽 `_ChatMessageBlock`）加时间行。
2. 手工验证：今天/昨天/跨年消息（可改系统时间或测服历史）、图文/视频/己方 pending。

回滚：移除 `Column` 时间行与 import 即可。

## Open Questions

- 无。范围与格式化函数已锁定。
