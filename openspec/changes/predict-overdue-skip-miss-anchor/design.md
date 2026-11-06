## Context

逾期 `nextAt` 无法人工推档；hero「跳过」是换事件。探索选定：**从错过点再亲和重算**——`missAnchor = 被跳过的 nextAt`，亲和锚与加法起点均为该点，真 `lastAt` 仅展示。基线 `v2.1.4`；亲和/护栏/软标已有实现不动主公式。

## Goals / Non-Goals

**Goals:**

- 逾期非预约卡可跳过一档并重算。
- `missAnchor` 本机持久化；真发生推进后清除。
- 预测出口统一（卡 / 组件 / pending）。

**Non-Goals:**

- 改亲和 h、直方图 α；自动连滚到未来；预约；污染真历史。

## Decisions

1. **语义。**  
   跳过时 `missAnchor := 当前 pred.nextAt`。重算：`_collectAffinityIntervals(..., lastAt: missAnchor)`（仅换钟点锚），`interval` 仍加权中位/种子；候选 `nextAt = missAnchor + interval`（非真 L+）。返回模型 `lastAt` 字段仍为真发生 tip。  
   备选：N+旧Δ 滚一轮 — 拒绝，用户已选错过点重算。

2. **一次一点。**  
   不自动 while overdue 连跳；仍逾期则按钮保留。避免一次跳过跨过多档。

3. **存储。**  
   按 `deviceNo`+根 `eventId` 存 `missAnchor` 瞬时（ISO/unix）。新真 tip ≥ missAnchor 或 tip 日历上晚于锚则 clear。登出/清账号随既有 wipe。

4. **Predictor API。**  
   `predictNextForEventKey` 增加可选 `DateTime? missAnchor`：非空则亲和锚与加法起点用它；`cachedLastAt`/窗口 tip 仍决定展示 lastAt。直方图仍只用真 `times`。

5. **UI。**  
   逾期倒计时区块附近「跳过本次」；busy 防连点；成功后依赖 provider 刷新。不与 hero skip 文案混用职责。

6. **失败回退。**  
   锚下亲和 &lt;2：种子；再失败可 `missAnchor + 跳过前主中位`（若可知）或保持不可预测并提示——实现选「种子否则 null 并 toast」，避免静默假成功。

## Risks / Trade-offs

- [错过点钟点邻域样本稀 → 常软标/种子] → 可接受；用户可再跳或真记一笔。  
- [忘清 missAnchor → 真发生后仍从旧锚加] → 严格 tip 清除规则 + 调试日志。  
- [与软标叠加] → 正交；跳过是动作。

## Migration Plan

1. 存储 + predictor 锚参数 + 行组装注入。  
2. 卡上按钮与刷新。  
3. 手工：逾期跳过 → nextAt 前移；再记一笔 → 锚清除。  
4. 回滚：忽略 missAnchor 即可。

## Open Questions

- （已定）一次一点；错过点亲和重算；非自动连跳。
