## Context

竖列表大卡（`_PredictionEventCard` 非 compact）图区已是近 N 日准确率柱 + 点柱小结，空态有示例柱（`predict-list-accuracy-sample-empty`）。卡上仍堆叠倒计时/上一次/计时停止等预报语义；计分仍为 `|Δstart|≤1800` 二元命中，细节「准/偏」，与产品「对照表 = 最近准确率」及时间×量加权意图不符。history 已具备 `expectStartTime` / `expectEndTime` / `expectAmount`；目录 `eventType=one` 为一次性，无用量/时长量线。

## Goals / Non-Goals

**Goals:**

- 竖列表对照卡仅名+logo+推演开关 + 准确率图区（含标题/示例标注/小结）。
- 细节单行「预计时刻[·量] → 实际时刻[·量]」；整行绿/黄/红；无准/偏；一次性不展示量。
- 合成分 = 时间对齐×0.7 + 量对齐×0.3（缺量归一为纯时间）；日柱 % 同源；时长进量槽。

**Non-Goals:**

- 横滑/瀑布 compact 改版；把停止入口迁到其它页面；改 Go / expect 打戳协议；新建测试文件。

## Decisions

1. **Chrome 裁剪范围（竖列表非 compact）**  
   有准确率图区时（`pred != null` 且非 compact）：隐藏 relative、上一次、倒计时/预约改约块、「预计约…」、补充上次/下次/间隔 CTA、**计时中整块（已用时/ETA/停止）**。保留标题行（logo+名+Switch）与图区。横滑/瀑布路径不改。  
   *备选*：计时中例外露停止 → 否决（产品明确只要准确率图）。

2. **标题**  
   真/示例柱上方居中：`预测准确率分布图`；示例追加 ` · 示例数据`。整段 `color: accent`（可略降 alpha 保持可读）。去掉独立 muted「示例数据」行。

3. **返回**  
   小结顶栏左侧 `Icons.arrow_back_ios_new`（或等价 chevron）InkWell，无「近7日」字。旁侧可保留「今天 · 预测小结」；示例可带「· 示例」。

4. **量槽与一次性**  
   - 有可用 `expectAmount` 且实际用量可解析 → 量槽为用量+单位。  
   - 否则若有可用时长期望（`expectEndTime−expectStartTime` 或等价）且实际有结束 → 量槽为时长文案（复用既有中文时长格式）。  
   - 叶子/根为 **`eventType=one`（一次性）** 或无法解析任何量维 → **不展示** `·` 量段，计分走缺量路径。  
   - 禁止对无戳行重放预报填量。

5. **对齐率映射（0–100）**  
   - **S_time**：`d = |actualStart−expectStart|` 秒；`d ≤ 1800` → 100；`d ≥ 7200` → 0；中间线性插值。  
   - **S_qty**（用量或时长同一相对误差）：`err = |a−e| / max(|e|, ε)`；`err ≤ 0` → 100；`err ≥ 0.5` → 0；中间线性。  
   - **合成分**：两维都有 → `0.7*S_time + 0.3*S_qty`；仅时间 → `S_time`。  
   - **色**：`score ≥ 70` 绿；`≥ 40` 黄；否则红。整行文字同色。

6. **日柱 %**  
   该日每条合格发生算一行合成分；日 `% = round(mean(scores))`。无合格行 → 该日 null（不画柱）。示例工厂用同一展示形态与三色，假 % 仍故意起伏。

7. **模型**  
   扩展/替换 `PredictAccuracySample`：保留 expect/actual 时刻；可选 expect/actual 量文案或原始量值；`score` 与展示用色档；`hit` 可废弃或改为 `score≥70` 仅内部兼容。聚合与 UI 只读新字段。

## Risks / Trade-offs

- [竖列表无法停表] → 产品接受；停止仍在横滑/其它入口；若投诉再开例外。  
- [旧日柱与新分不一致] → 本 change 强制同源，接受历史「命中率」观感变化。  
- [无 expect 量戳的行只有时间] → 缺量归一；与一次性一致。  
- [单位/时长文案过长] → 单行 ellipsis；不换行。

## Migration Plan

1. 先落地计分纯函数与示例工厂，再改图区 UI 与卡 chrome。  
2. 回滚：恢复卡 chrome 条件分支与旧二元命中/% 即可。

## Open Questions

- （已定）缺量归一、时长进量槽、70/40 切档、柱同步、一次性不展示量、计时无停止条。
