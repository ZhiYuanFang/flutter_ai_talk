## Context

先热后软已落地：primary→gePrimary→crossDay 皆冷则保留 primary + `todConfidenceLow`。逾期手工 missAnchor 跳过无法多端同步，且清锚与 tip 源不一致会闪回。产品改为：**算法内最多自动跳 1 次**——以冷点为亲和锚重估间隔，落点仍为真 `lastAt + interval₁`；去掉本机跳过。基线 `openspec/specs/v2.1.4.md`；承接软标 / 废止 `predict-overdue-skip-miss-anchor` 手工路径。

## Goals / Non-Goals

**Goals:**

- 皆冷后一次换锚重估；热则采用，仍冷则软标留下。
- 种子路径不做自动跳。
- 删除手工跳过与 missAnchor 持久化。
- 预测仍为共享历史的纯函数（多端一致）。

**Non-Goals:**

- 改亲和 h、直方图 α、7 日窗。
- 自动连跳 &gt;1；`miss + interval` 时间轴滚档。
- 服务端下发预测。

## Decisions

1. **触发点。**  
   非种子且 primary→gePrimary→crossDay **皆未过护栏**之后，才进入自动跳。已有热候选不跳。  
   备选：任一冷候选即跳 — 拒绝，破坏先热后软序。

2. **一次跳的公式。**  
   令 `nextAt₀` 为皆冷时保留的 primary（`lastAt + interval₀`）。  
   以 `nextAt₀` 为 `_collectAffinityIntervals` 的钟点锚，重算加权中位得 `interval₁`（样本不足则本次自动跳失败，退回 `nextAt₀` 软标）。  
   `nextAt₁ = lastAt + interval₁`（**加法基仍是真 tip，不是 nextAt₀**）。  
   若 `accept(nextAt₁)` → 返回热、`todConfidenceLow=false`；否则返回 `nextAt₁`、`todConfidenceLow=true`。  
   **不得**再跳第二次。  
   备选：`nextAt₁ = nextAt₀ + interval₁` — 拒绝；用户明确要真最近一次 + 新间隔。

3. **种子 / 冷启动。**  
   `usedSeed == true`（用户填间隔或无足够亲和样本走种子）：MUST NOT 自动跳；冷则既有 `seedSoft`。

4. **拆除 missAnchor。**  
   删除 store、provider、UI 按钮、wipe/widget/rows 注入与 `clearStale`；`predictNextForEventKey` / `predictAllUpcoming` 去掉 miss 参数（或忽略并删调用方）。残留 prefs 可忽略或启动时 clearAll 一次。

5. **日志。**  
   `[PredictInterval]` 增加 `autoSkip=0|1`、必要时 `medianMin` 新旧；禁止刷直方图。

## Risks / Trade-offs

- [I₁≈I₀ → 跳了像没跳] → 可接受；仍软标。  
- [换锚后样本更稀 → 跳失败] → 退回 nextAt₀ 软标。  
- [与未归档 miss-anchor 冲突] → 本 change 废止手工路径，实现时拆代码。

## Migration Plan

1. Predictor：皆冷后一次 reanchor；种子旁路。  
2. 拆 miss UI/存储/接线。  
3. 手工：皆冷→若 I₁ 不同则 nextAt 变；种子冷无连跳；无跳过按钮。  
4. 回滚：恢复皆冷 primarySoft +（可选）miss UI。

## Open Questions

- （已定）最大跳 1；落点 `lastAt+I₁`；种子不跳；无用户跳过按钮。
