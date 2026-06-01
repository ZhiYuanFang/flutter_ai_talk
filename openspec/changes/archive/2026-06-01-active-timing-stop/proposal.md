## Why

计时类事件（`eventNumber == 0` 且未设置结束时间）在主页历史行仅显示静态「开始计时」，用户无法感知已计时长，也缺少一键结束入口，需进详情编辑结束时间，路径长、易漏停。应在主页历史行与详情预览中实时展示已计时长，并提供直接停止（写入结束时间）。

## What Changes

- 新增进行中计时判定与时长格式化：不足 1 小时为 `MM:SS`（如 `05:23`），满 1 小时及以上为 `HH:MM:SS`（如 `01:12:05`）。
- 主页历史时间轴行：进行中记录在右侧尾注区每秒刷新时长，并显示「停止」按钮；多条同时进行时各行独立展示与停止。
- 历史详情预览模式：进行中记录展示动态「已计时长」与「停止」；点击停止调用既有 `POST /device/history/api/event/update` 写入 `endTime`，无二次确认。
- 停止按钮点击不得触发进入详情（主页行内）；停止成功后依赖既有 SSE/列表合并或本地刷新展示已结束状态。
- 已结束计时的尾注「用时…」文案与今日汇总规则不变。

## Capabilities

### New Capabilities

- `active-event-timer`：进行中判定、实时时长格式、停止更新契约及主页/详情共用的刷新节奏。

### Modified Capabilities

- `home-history-timeline-row`：计时进行中尾注由静态「开始计时」改为动态时长 + 停止控件。
- `history-detail-view-mode`：预览模式对进行中计时补充动态已计时长与停止操作。

## Impact

- `app/lib/data/history_line_format.dart`（或同级工具）：进行中时长格式化、判定辅助函数。
- `app/lib/ui/home_history_timeline_tile.dart`、`home_history_scroll.dart`、`home_screen.dart`：行 UI、秒级 tick、停止回调。
- `app/lib/ui/history_detail_screen.dart`：预览区动态时长与停止。
- 复用 `FeedRepository.updateHistoryRecord`，无新网关接口。
