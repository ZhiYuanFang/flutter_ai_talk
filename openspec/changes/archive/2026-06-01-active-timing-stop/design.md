## Context

- 进行中语义：`eventNumber == 0` 且 `endTime` 按 `historyInstantUnset` 为未设置；开始时刻为 `startTime ?? createdAt`（与 `historyHomeRowDisplay`、详情预览一致）。
- 结束计时：客户端调用 `updateHistoryRecord`，`endTime = DateTime.now()`，保留原 `remark` 与 `startTime`。
- 主页历史列表经 `HomeHistoryScroll` + `HomeHistoryTimelineTile` 渲染；详情默认预览模式（`history-detail-view-mode`）。

## Goals / Non-Goals

**Goals:**

- 主页历史行、详情预览：进行中每秒刷新已计时长；尾注/预览区提供「停止」，一点即停。
- 时长展示：`< 1` 小时 `MM:SS`（固定位、零填充）；`≥ 1` 小时 `HH:MM:SS`（如 `01:12:05`）。
- 多条同时进行：每行/每条记录各自时长与停止，互不影响。
- 存在任意进行中记录时启用单一 `Timer.periodic(1s)` 驱动 UI 刷新，无进行中则取消。

**Non-Goals:**

- 顶部固定计时条、今日汇总 chip、语音「停止」指令。
- 修改已结束记录的「用时」展示规则（仍用 `formatDurationForEvent0`）。
- 停止二次确认对话框；新增网关 stop 专用接口。

## Decisions

1. **格式化函数**  
   在 `history_line_format.dart`（或紧邻模块）新增 `isActiveTimingRecord`、`formatActiveTimerElapsed(Duration)`：  
   - `duration.inHours < 1` → `mm:ss` 两位分、两位秒；  
   - 否则 → `h:mm:ss` 两位时、两位分、两位秒（小时可超过 23，如 `25:03:10` 表示 25 小时）。  
   与结束后「用时12分钟」分离，避免改动既有 history-line 已结束分支。

2. **主页行 UI**  
   `HomeHistoryTimelineTile` 在 `isActive` 时尾注为 `Row`：`Text(时长, tabular figures)` + `TextButton('停止')`；`onStop` 由 `HomeScreen` 注入并 `stopPropagation`（`InkWell` 外包停止区或独立 `GestureDetector`），避免误触 `onRecordTap`。  
   行高仍尽量保持 32–36px；停止用紧凑 `TextButton`（`minimumSize`/`tapTargetSize` 收紧），必要时进行中行允许尾注区 `FittedBox` 缩放。

3. **主页 tick**  
   `HomeScreen` 扫描 `_items` 是否存在进行中；有则 `Timer.periodic(1s)` + `setState` 传入 `tickNow` 至 `HomeHistoryScroll` → tile 计算 `now.difference(start)`。

4. **停止实现**  
   共享逻辑：`updateHistoryRecord(id, remark: 原值, startTime: 原 start, endTime: now)`；请求中禁用对应 id 的停止按钮防连点；失败沿用仓库 Toast。成功后可乐观更新本地 `rawPayload.endTime` 或等待 SSE（与现列表合并一致）。

5. **详情预览**  
   `HistoryDetailScreen` 预览体：进行中时展示「已计时长」行（动态）+ 「停止」`FilledButton`/`TextButton`；可移除冗余静态「状态：计时中」行。  
   页面级 `Timer` 与主页相同节奏；停止成功后 `reload` 记录或 `pop(true)` 通知列表刷新。编辑模式非必须重复停止入口（预览即可）。

## Risks / Trade-offs

- **[Risk] 窄屏尾注挤占事件名** → 停止用短文案、尾注 `Flexible`+省略号，事件名 `Expanded` 优先截断。  
- **[Risk] 停止后 SSE 延迟** → 乐观写 `endTime` 或短暂保留 loading 态。  
- **[Risk] 系统时间跳变** → 与详情编辑一致，以本地 `now - start` 展示，接受时钟误差。

## Migration Plan

- 纯客户端发布；无数据迁移。回滚即恢复静态「开始计时」与无停止按钮。

## Open Questions

- （已确认）满 1 小时格式为 `HH:MM:SS`（`01:12:05`），不足 1 小时为 `MM:SS`（`05:23`）。
