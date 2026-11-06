## Context

`predict-tod-cold-soft-label` 在倒计时区块上方单独放「此刻把握不足」；`predict-overdue-show-next-at-clock` / `predict-far-countdown-show-clock` 在时刻态把标题改成「预计{名}时刻」。二者叠在一起时占两行。产品选定：**仅时刻态**合并为一行「此刻把握不足 · 预计{名}时刻」。基线对照 `openspec/specs/v2.1.4.md`；承接上述未归档/已实现 UI。

## Goals / Non-Goals

**Goals:**

- 时刻态 + `todConfidenceLow`：软标与「预计…时刻」同行，中间「 · 」。
- 倒计时态：软标仍独占一行，标题仍为「距离下次…倒计时」。
- 无软标时标题与大数字不变。

**Non-Goals:**

- 改预测算法 / `todConfidenceLow` 判定。
- 倒计时态也做 · 合并。
- 改用量 expect「预计约…」行；小组件文案。

## Decisions

1. **合并条件。**  
   `showEstimatedClock == true`（逾期或剩余 &gt;6h）且非预约、`todConfidenceLow`：标题行文案 = `此刻把握不足 · 预计$titleName时刻`，**不再**渲染独立 soft 行。  
   备选：凡有软标都与任意 caption 合并 — 拒绝；倒计时态标题过长。

2. **实现落点。**  
   仅改 `_buildAppointmentAwareCountdown`：有 soft + 时刻态时拼字符串作唯一 caption；有 soft + 倒计时态时仍 soft 行 + caption 两行。样式沿用 caption 字号/淡色即可（不必双色）。

3. **expect 行。**  
   「预计约…」仍可在标题行之上单独出现；与合并标题正交。

4. **过长。**  
   单行 `Text` + `maxLines: 1` + ellipsis；横屏紧凑可接受截断「时刻」尾部。

## Risks / Trade-offs

- [事件名很长导致软标被挤掉] → ellipsis；必要时后续再拆字重。  
- [与未归档 soft-label 「标题上方」字面冲突] → 本 change 规格明确时刻态改为同行；倒计时态仍「上方」。

## Migration Plan

1. 改 countdown 组装逻辑。  
2. 手工：时刻态冷 → 一行带 ·；倒计时态冷 → 仍两行；热区 → 无软标。  
3. 回滚：恢复独立 soft 行即可。

## Open Questions

- （已定）仅时刻态合并；分隔符「 · 」。
