## Context

`predict-interval-tod-affinity-guard` 已落地：亲和加权中位 + 环形直方图护栏；主候选冷则试「≥主中位」「跨自然日」，皆冷则 `predictNextForEventKey` 返回 `null`，热态卡露出「补充大概多久一次」。探索结论要改为 **先热后软**：热区候选优先；无热区时保留 `nextAt` 并在 UI 标「此刻把握不足」。基线对照 `openspec/specs/v2.1.4.md`；行为承接亲和护栏 change。

## Goals / Non-Goals

**Goals:**

- 直方图仍用于区分热/冷候选；优先采用通过相对峰值阈值的候选。
- 无热区候选时保留最终 `nextAt`（默认主中位或种子），并设显式「钟点把握不足」标志。
- 智能预测非预约热态卡倒计时上方展示固定文案「此刻把握不足」。
- 样本 &lt; 密度下限时仍跳过护栏（不标不足）。

**Non-Goals:**

- 放宽亲和 h、改 7 日窗、显式双峰聚类。
- 小组件 / Live Activity / pending 出站与 App 卡分层策略（本 change 与 App 共用同一 `nextAt`）。
- 预约根文案、准确率柱排除冷预测、设置页调试 UI。
- 恢复「补充大概多久一次」作为冷区并存 CTA。

## Decisions

1. **先热后软选择序。**  
   对非种子路径：按序评估 primary → gePrimary → crossDay；**第一个通过护栏的候选**胜出，`todConfidenceLow = false`。若无一通过，采用 **primary**（主中位）并 `todConfidenceLow = true`（即使 gePrimary/crossDay 也算得出但同为冷，仍用 primary，避免用更长冷间隔「假改善」）。  
   种子路径：无 gePrimary/crossDay；种子 `nextAt` 过护栏则 `todConfidenceLow = false`，否则保留种子 `nextAt` 且 `todConfidenceLow = true`（不再因冷返回 null）。  
   备选：皆冷时选相对峰值最高者 — 第一版不做，规则更绕。

2. **模型字段。**  
   在 `EventNextPrediction` 增加 `bool todConfidenceLow`（默认 `false`）。**不得**用现有样本数 `confidence` 兼表冷热。行/UI 只读该布尔决定文案。

3. **护栏函数语义。**  
   `_passesTodHistogramGuard` / 相对峰值逻辑保留；调用方从「不过就丢弃整根」改为「记录是否曾仅得冷候选」。样本不足跳过护栏时视为通过且 `todConfidenceLow = false`。

4. **UI。**  
   仅非预约、热态、有倒计时、`todConfidenceLow == true`：在倒计时区块内、倒计时标题「距离下次…」之上（与 expect 行同级可叠：冷文案在 expect 之上或之下择一，推荐 **冷文案在 expect 之上**，更贴近「对整次预测的把握」）。文案固定「此刻把握不足」；caption 字号、强调色淡于主倒计时。预约 / 骨架 / 关推演 / 无 pred MUST NOT 展示。

5. **Debug。**  
   `[PredictInterval]` 增加是否软标（如 `soft=1`）与选用 path；禁止刷直方图全量。

## Risks / Trade-offs

- [冷 nextAt 进入小组件/提醒] → 本 change 接受与卡一致；若后续要分层另开 change。  
- [「今晚再来」+ 把握不足仍可能不准] → 先热后软已尽量跳到热跨日；软标降低误导。  
- [用户无法再靠补间隔「纠正」冷预测] → 有 pred 即无 CTA；可靠真实发生刷新分布。若需手动覆盖另议。  
- [与未归档的亲和护栏规格冲突] → 本 change MODIFIED 同名 Requirement，归档时以本版为准。

## Migration Plan

1. 改 `predictNextForEventKey` 终态与字段；UI 接线文案。  
2. 用「主候选冷、跨日热」与「皆冷」两条手工路径验收。  
3. 回滚：恢复冷则 `return null` 即可。

## Open Questions

- （已定）皆冷保留 primary；文案「此刻把握不足」。  
- 出站通道是否单独抑制冷预测：本 change 不做。
