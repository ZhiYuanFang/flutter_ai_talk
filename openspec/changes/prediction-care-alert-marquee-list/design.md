## Context

`prediction-care-alert-banner` 已落地：本地双基准引擎 + tip/列表间单条 Banner + `/prediction/alert` 单 reason 详情。产品改口为按事件全量展示，区块内跑马灯严格单行裁切，同事件多规则一句话摘要、详情展开全量原因。

## Goals / Non-Goals

**Goals:**

- 输出全部过阈值候选；按 `eventId` 聚合成跑马灯条目。
- 区块固定约一行高度，**严格裁切只见当前一条**（不露下一条）。
- ≥2 条自动上下轮播；1 条静止；可手动滑动；点当前条进该事件详情。
- 同事件多规则：单行摘要（类型标签按优先级排序连接）；详情列出全部 `CareAlertReason`。
- 无条目时整块隐藏；无新增 HTTP。

**Non-Goals:**

- 不改三条规则阈值/期望表数值（除非聚合需要小 dedupe）。
- 不做水平跑马灯、不露半行预览、不推送通知。
- 不改 tip；不负责事件卡片 list/grid 布局（见并行 change `prediction-layout-list-grid`）。

### 与布局 change 并存

- 跑马灯插在 tip 与 **事件卡片区**之间，宽度始终全宽。
- 下方卡片变为 2 列网格时，跑马灯 **不得** 缩进网格列，裁切仍严格单行。

## Decisions

### D1：引擎 API 形态

- **选择**：`evaluateCareAlertCandidates(...) → List<CareAlertReason>`（全量过阈值，不再 Top1 过滤）；另提供 `aggregateCareAlertsByEvent(candidates) → List<CareAlertEventItem>`。
- **备选**：保留 Top1 函数加 flag — 拒绝，避免双语义。
- 旧 `evaluateCareAlert` 改为调用 candidates + 取首条仅作兼容时可删，实现阶段直接替换 provider。

### D2：事件聚合 `CareAlertEventItem`

字段建议：

- `eventId` / `eventName`
- `reasons: List<CareAlertReason>`（同事件内按类型优先级升序，再按 score 降序）
- `summaryLine`：`{eventName}：{typeLabel1}、{typeLabel2}`（顿号连接）
- `sortKey`：该事件最高优先级（最小 priority 值）+ 该优先级下最大 score

多事件排序：先类型优先级，再 score。

### D3：跑马灯 UI

- 容器：玻璃拟化外壳 + 固定标题「值得留意」+ **Viewport 高度 = 单行内容行**（`clipBehavior: Clip.hardEdge`）。
- 实现倾向：`PageView.vertical`（`viewportFraction: 1.0`）或定高 `ListView` + `ScrollPhysics` + `Timer` 动画 `animateTo`；**严格一页一行**，禁止 peek。
- 仅 1 条：不启动 Timer。
- ≥2 条：间隔约 3–4s 切下一条，循环；用户拖动后暂停 ≥3s 再恢复自动播。
- 点击：以**当前页 index** 对应的 `CareAlertEventItem` push `/prediction/alert`。

### D4：详情页

- `extra`：`CareAlertEventItem`（含全量 reasons）。
- UI：事件名 + 摘要 + 每个 reason 一块结构化字段（复用现有 kv 展示）。
- 无 extra / 类型不对：保持空态「暂无预警详情」。

### D5：Provider

- `predictionCareAlertProvider` → `List<CareAlertEventItem>`（空列表 = 隐藏区块）。
- 仍 `watch` range ensure + clock；**不**滤推演开关；不新发 HTTP。

## Risks / Trade-offs

- [条目很多时轮播久] → 可接受；排序把高优放前。
- [手动滑与 Timer 抢滚动] → 拖动暂停再恢复。
- [摘要过长] → 单行 `maxLines: 1` + ellipsis；完整信息在详情。
- [与旧 Top1 spec 冲突] → 本 change delta 明确替换行为。

## Migration Plan

- 纯客户端；替换 Banner/provider/路由 extra 形态。
- 回滚：恢复单条 Top1 UI 与评估函数。

## Open Questions

- 自动轮播间隔最终手感（默认 3.5s，实现可微调，无需再开 change）。
