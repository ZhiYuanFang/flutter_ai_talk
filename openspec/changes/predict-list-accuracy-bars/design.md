## Context

- 预测竖列表卡（`smart_prediction_screen` 非 compact 路径）图区现为 `_LookbackChart`：近 N 日实际发生时刻折线，Y 为当日时刻分钟。
- `history-expect-fields-*` 已在本地/服务端落 `expect*`；准确率可按「已存 expectStartTime」审计计分。
- 误落地：`trends-n-day-predict-accuracy` 在趋势中心 `TrendNDayBarChart` 叠了 `%`（及用户感知的「小结」方向），**应回滚**；产品面是预测竖列表。
- 已有纯函数 `trend_predict_accuracy.dart`（30 分钟窗、按日 %、无样本 → null）可上移/复用于预测卡，不必绑死 `TrendPoint`。

## Goals / Non-Goals

**Goals:**

- 竖列表大卡图区：近 7 日准确率柱（柱高 = 0–100%，柱顶整数 `%`）。
- 无合格样本日：空位，不画柱、不标 0%。
- 点有样本柱 → **同卡图区整块替换**为该日预测小结（该根事件当日每次：预计 vs 实际）；「近7日」返回柱图。
- 回滚趋势中心准确率 UI；量柱仅反映总量。

**Non-Goals:**

- 横滑 / 瀑布 / 投屏布局图区不变。
- 趋势中心新能力、独立准确率页、Go API、duration/amount 维、重放伪造 expect。

## Decisions

### D1 — 表面：仅预测竖列表大卡

- **选**：`!compact` 纵向列表卡图区替换 `_LookbackChart`。
- **不选**：趋势中心叠标（已否决）；横滑/瀑布同步（用户明确不在意）。

### D2 — 柱语义：准确率，不是喂养量

- Y 轴 0–100；柱高 = 日准确率；柱顶 `%`。
- 空日：无柱、无 `%`（与「无样本不伪造」一致）。

### D3 — 小结 = 卡内替换图区

- 选中日状态存在**单卡 State**（或列表层按 `rootEventId` 记住选中日）。
- 图区二态：`bars` | `daySummary(day)`；切换不导航、不弹 sheet。
- 小结内容：该自然日、该卡事件根下，每条合格样本一行（预计开始 / 实际开始 / 命中与否）；无合格样本不得进入小结态（点空位无操作）。
- 返回：图区内显式「近7日」（或等价），清除选中日。

### D4 — 计分复用既有纯函数

- 命中：`|actualStart − expectStartTime| ≤ 1800s`；仅 `expectStartTime > 0` 样本。
- 优先把 `trend_predict_accuracy` 泛化为读 history/`HistoryEvent`（或薄适配），预测卡与（若仍需）其它调用共用；**禁止**重放预测引擎填假 expect。

### D5 — 回滚 trends 误改

- 去掉 `TrendNDayBarChart.accuracyPercents` 绘制与 `trends_screen` 注入；可保留纯函数文件供预测卡引用，或迁到 `predict_accuracy.dart` 后删 trends 引用。
- `trends-n-day-predict-accuracy` 标记 superseded，不再继续其任务 3.2。

### D6 — 数据窗

- 与卡内原 lookback 一致：默认近 7 个自然日（含今天），根事件 = 该卡 definition root；历史源与预测页同源（含 recall seeds 的 range 亦可，但计分只认真实 history 带 expect* 的行）。

## Risks / Trade-offs

- [Risk] 打戳前历史全无样本 → 七天空柱 → Mitigation：空态文案「暂无预测对照」类，与旧折线空态同级。
- [Risk] 卡 InkWell 整卡点击与点柱冲突 → Mitigation：柱/小结区 `absorb` 或局部 GestureDetector，阻止冒泡到 `onCardTap`。
- [Risk] 小结列表条目多撑破固定 `chartH` → Mitigation：图区内可滚动短列表，高度仍受原 chart 槽约束。
- [Risk] 趋势回滚与预测并行改同一 accuracy 文件 → Mitigation：先抽纯函数、再改两端 UI。

## Migration Plan

1. 回滚 trends UI 准确率。
2. 预测竖列表接线柱图 + 卡内小结态。
3. 手工：有 expect* 日有柱与 `%`；点柱见小结；返回见柱；趋势中心无 `%`。

## Open Questions

- （无阻塞）小结行是否显示误差分钟数：v1 可只显示预计/实际时刻 + 命中标记。
