## Context

`predict-overdue-show-next-at-clock` 已让逾期大数字改为 `formatPredictionEstimatedClock`，标题改「预计…时刻」。探索结论：剩余 **&gt; 6h** 时同样 **只显示时刻**（非双行）；跨日日期前缀要小字。基线 `v2.1.4`。

## Goals / Non-Goals

**Goals:**

- `until > 6h`（未逾期）→ 与逾期相同的「只显示时刻」主数字 + 「预计{名}时刻」标题。
- 时刻串拆成可选日期前缀（小）+ `HH:mm`（大）。
- `until ≤ 6h` 且未逾期 → 保持 `H:MM:SS` + 「距离下次…倒计时」。

**Non-Goals:**

- 双行倒计时+时刻；设置页可调阈值；小组件/tip。

## Decisions

1. **阈值。**  
   严格 **`nextAt.difference(now) > Duration(hours: 6)`**（用户「&gt;6h」）。恰好 6h 仍倒计时。

2. **统一「时刻态」。**  
   `showClock = overdue || until > 6h`。时刻态共用标题与时钟渲染；未逾期远距不显示「已超时」相对句（相对句逻辑不变，仅大数字/标题切换）。

3. **日期小字。**  
   停止把整串丢进单一大 `Text`。返回结构或拆函数：`datePrefix`（可空）+ `hm`。UI：`Row`/`RichText`，前缀用 caption 级或约主数字 0.55–0.65 倍字号、字重可略轻；`HH:mm` 仍用 `countdownFontSize` + w700。今天 `datePrefix == null`。

4. **与逾期 change 关系。**  
   可把 `formatPredictionEstimatedClock` 拆成 parts；逾期路径一并改用小字日期（体验行为增强，规格在本 change 写明）。

## Risks / Trade-offs

- [远距只看钟点不知还剩多久] → 产品取舍；旁侧相对「约 X 小时后」仍可提示。  
- [FittedBox 缩放导致日期/时分比例漂移] → 先锁字号比再 scale 整行，或日期不参与极端放大。  
- [恰好 6h 边界跳变] → 接受；文档写清 `>`。

## Migration Plan

1. 拆时钟 parts + UI 小字；门闩加入 `until > 6h`。  
2. 手工：&gt;6h 只见时刻+新标题；≤6h 倒计时；跨日日期更小。  
3. 回滚：去掉远距门闩与拆分渲染。

## Open Questions

- （已定）&gt;6h 替换为只显示时刻；日期小字；阈值严格 `>`。
