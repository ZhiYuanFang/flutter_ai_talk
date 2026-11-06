## Context

`formatPredictionCountdownHms(..., overdue: true)` 固定返回 `00:00:00`；卡上标题恒为「距离下次{名}倒计时」。产品要在逾期时展示预估 `nextAt` 钟点，并改标题。相对行「已超时」可保留。基线：`openspec/specs/v2.1.4.md`。

## Goals / Non-Goals

**Goals:**

- 逾期大数字 = 预估本地时刻；今天不加「今天」。
- 逾期标题 = 「预计{事件名}时刻」；未逾期不变。
- 预约与非预约热态卡凡走同一倒计时区块者行为一致。

**Non-Goals:**

- 小组件 native / tip 栏 overdue 句式。
- 改 `isOverdue` 判定或排序。
- 秒级展示（`HH:mm` 即可）。

## Decisions

1. **格式函数。**  
   逾期分支改为调用与 `formatWidgetLastAt` 同日界规则的钟点串：今天 `HH:mm`；昨天 `昨天 HH:mm`；更早 `M月D日 HH:mm`。可抽共享 helper，或让 `formatPredictionCountdownHms` 在 overdue 时直接格式化 `nextAt`（仍接收 `now` 做日界）。未逾期仍为 `H:MM:SS` 倒计时。  
   备选：逾期也带秒 — 拒绝，噪声大。

2. **标题。**  
   `_buildAppointmentAwareCountdown` 增加 `overdue`（或由调用方传入标题字符串）：  
   - 未逾期：`距离下次$titleName倒计时`  
   - 逾期：`预计$titleName时刻`  
   事件名与现标题同一 `titleName` 来源。

3. **范围。**  
   仅智能预测卡倒计时区块（含预约点按改约块）。`formatPredictionGridRelative` 的「已超时」不改。

4. **「此刻把握不足」。**  
   与逾期正交：软标仍可叠在标题之上。

## Risks / Trade-offs

- [长事件名 +「预计…时刻」换行] → 既有 ellipsis/字号；可接受。  
- [跨多日 overdue 显示「M月D日」偏长] → 与「上一次」一致，可接受。  
- [调用方误传 overdue=false 却已过期] → 数字函数以 `overdue` 参数为准，与现卡逻辑一致（`pred.isOverdue(now)`）。

## Migration Plan

1. 改格式函数 + 标题分支。  
2. 真机：今日逾期看 `HH:mm` 无「今天」；昨日逾期看「昨天」；标题切换。  
3. 回滚：恢复 `00:00:00` 与原标题。

## Open Questions

- （已定）今天不加「今天」；标题改为「预计{名}时刻」。
