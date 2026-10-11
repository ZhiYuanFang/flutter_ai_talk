## Context

`predict-expect-amount-duration` 已为非预约根维护 duration 加权中位。进行中卡（`isActiveTimingRecord`）今日只显示 elapsed。同步通道 `predict/imminent/pending` 专用于下次 `nextAt` 推送，不宜混入进行中 ETA。Python intent 主图经 `speak_history` 播报进行中。

## Goals / Non-Goals

**Goals:**

- `expectEndAt = startAt + expectDurationSec`（duration 有把握时）。
- 列表与网格进行中卡均展示；超时文案 A。
- 独立 PUT 全量同步；字段便于 Python 按叶子/根/historyId 匹配。

**Non-Goals:**

- 改 imminent 推送；无 duration 时猜测结束；本仓改 Python/Go 实现（仅契约对齐）；桌面小组件。

## Decisions

### D1：算法

复用根上已胜出或单独可算的 **duration** 线（≥2 样本加权中位秒）。进行中本身不计入 duration 样本。无把握 → 无 ETA 行、不同步该项。

### D2：文案（超时 A）

- 未超时：`预计约 HH:mm 结束`（本地墙钟）。
- 超时：`预计约 HH:mm 结束 · 已超时`（仍显示原预计点）。

列表与 compact/网格同一套文案函数。

### D3：同步契约（与 Go 对齐）

`PUT /device/api/predict/active-eta/pending`（路径以实现为准，须经 gateway；**不得**复用 imminent 路径）：

```json
{
  "deviceNo": "...",
  "items": [
    {
      "rootEventId": 12,
      "leafEventId": 34,
      "historyId": "optional-server-id",
      "title": "睡眠",
      "startAt": 1710000000,
      "expectEndAt": 1710003900
    }
  ]
}
```

空 `items` 清空。触发：本机开始/停止计时、影响 duration 的本机历史变更后（与 imminent 相同的「仅本机合格变更」精神）；single-flight、指纹、熔断。

### D4：与 imminent 隔离

active-eta **不** PublishDelayed、不参与推送对账。

## Risks / Trade-offs

- [duration 未就绪] → 不展示；停止后清空同步。
- [多进行中] → 每条进行中一条 item（按根挂卡现状可一对一）。
- [pending 乐观 id] → historyId 可空，靠 leaf+startAt 匹配。

## Migration Plan

1. Go 先上 PUT/GET/Redis；Flutter 再同步；Python 接 speak_history。
2. 回滚：停 PUT；Redis 可被空列表清空。

## Open Questions

（无。）
