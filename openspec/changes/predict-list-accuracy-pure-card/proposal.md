## Why

预测竖列表「对照」卡仍混杂下次倒计时、上一次、计时停止等预报操作语义，且准确率细节只有到点准/偏、不计用量/时长；用户无法把对照表当成「最近预报准不准」的纯视图。需要把竖列表对照卡收成准确率专用面，并按时间/量加权计分与绿黄红呈现。

## What Changes

- **竖列表对照卡 chrome（非 compact）**：仅保留事件名 + logo + 推演 Switch；MUST 隐藏下次预计/倒计时、上一次发生、relative、「预计约…」、计时中已用时/停止条、补充 CTA 等非准确率内容。事件正在计时时，该竖卡仍只展示准确率图，MUST NOT 展示停止条。
- **柱图标题**：居中「预测准确率分布图」，文案色随事件 accent；示例态为「预测准确率分布图 · 示例数据」，两段均随 accent（取代单独 muted「示例数据」行）。
- **小结返回**：用左箭头控件返回柱图，MUST NOT 再用「近7日」文案。
- **细节行**：单行 `预计 HH:mm[ · 量] → 实际 HH:mm[ · 量]`；MUST NOT 展示「准/偏」。量槽：amount 用用量+单位；duration 胜出/有时长戳时用时长文案进量槽；**一次性（`eventType=one` / 无量线）MUST NOT 展示量槽**。
- **计分**：时间对齐率 70% + 量对齐率 30% 加权得合成分；缺量（含一次性）→ 整行只用时间对齐（权重归一）。合成分 ≥70 绿、40–69 黄、&lt;40 红，整行同色。
- **日柱 %**：与上述同一套合成分聚合同步，MUST NOT 仍只用到点 ±30min 二元命中而与细节脱节。
- **示例工厂**：示例细节与假柱须符合新行形态与三色分布；仍不写 history。
- **非目标**：不改横滑/瀑布 compact 卡主布局职责；不改 Go API；不新建 `**/test/**`；不把停止入口搬到其它 Tab（本 change 仅藏竖列表对照卡上的停止条）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-list-accuracy-bars`：对照卡纯准确率 chrome；标题/返回/细节行形态；时间×量加权计分与绿黄红；日柱 % 同步；一次性不展示量。

## Impact

- Flutter：`smart_prediction_screen.dart`（竖列表 `_PredictionEventCard` chrome 与 `_PredictAccuracyChartPane`）、`trend_predict_accuracy.dart`（样本模型、对齐率、日聚合、示例工厂）。
- 依赖已有 history `expectStartTime` / `expectEndTime` / `expectAmount` 与目录 `eventType`；禁止重放伪造 expect。
- 无新 HTTP；无 Android/iOS 原生；无 R8 影响。
- 关联：在 `predict-list-accuracy-sample-empty` 之上叠抛光与计分，并**推翻**其「保留卡上半倒计时/上一次」非目标。
