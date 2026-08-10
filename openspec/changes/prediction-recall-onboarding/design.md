## Context

智能预测主页依赖 `predictionRangeHistoryProvider` + `buildSmartPredictionRows`；空/不足历史时行列表为空。算法门槛见 `event_next_predictor`：`kMinIntervalForPrediction`（15m）、`kMinSamplesForPrediction`（2）→ 实际约需 ≥3 个可计数发生点。探索结论：策略 C 合成种子、不进喂养、按根缺口排队、真历史追上丢种子、内嵌悬浮卡、逐卡慢速思考、根集合全部 `parentId==null`、无子根仅自身一钮。

## Goals / Non-Goals

**Goals:**

- 缺口根可完成回忆采集并驱动本地推演生效。
- 种子与喂养历史严格隔离。
- 悬浮卡 + 逐卡思考 + 收尾 CTA 的完整引导体验。

**Non-Goals:**

- 不把种子同步到服务端 history；不在喂养时间线展示种子。
- 不降低全局算法门槛；不为种子单独放宽 min samples。
- 不新建 `**/test/**`。
- 不改陪伴 / VIP / care-alert 主路径。

## Decisions

1. **缺口判定（与算法同源）**  
   对每个 `rootEvents(catalog)`：用真历史（range ± 必要 active）按根聚合 `occurrenceInstant`，统计合格间隔样本数。未达 `kMinSamplesForPrediction`（在 ≥2 发生点且间隔 ≥15m 规则下）→ 列入缺口队列。已跳过关推演的根**不进**队列（或进队但仅展示「已跳过」状态——默认：**跳过后不进队**，直至用户在预测卡重新打开推演）。

2. **种子存储 `PredictionRecallSeedStore`**  
   按 `rootEventId` 持久化：`lastAt`、`interval`、`leafEventId`（可等于 root）、合成 `occurrenceAts`（至少 3 个，由 lastAt 向前按 interval 推）、可选文案字段。目录/prefs 与 `history_media`、喂养 history 无关。  
   **合成**：`t0=lastAt, t1=lastAt-interval, t2=lastAt-2*interval`（保证间隔 ≥15m；interval 滚轮最小值 ≥15m）。  
   供预测时：将合成点转为**仅内存**伪 `HistoryRecord`（或直接扩展 predictor 接受 `List<DateTime>`），**merge** 进 `buildSmartPredictionRows` 的 history 入参；伪记录不得写入 `FeedRepository` / homeHistory。

3. **真历史追上即丢**  
   每次构建预测前/ensure 后：若某根真历史已达标，`clearSeed(rootId)`。该根不再出现在缺口队列。

4. **UI 结构**  
   `SmartPredictionScreen`：当缺口队列非空且引导未在本会话点 CTA 完成（或队列仍非空）时，主内容区用内嵌 PageView 盖住列表空态；每页一张 elevates/glass 悬浮卡。流程态机：`card(i) → thinking(i) → card(i+1) → … → finale CTA`。  
   - 时间：Cupertino 滚轮到分钟；`eventType==time` 文案「上次结束」。  
   - 叶子：`childrenOf(root)`；空则单钮 = 根自身。  
   - 跳过：`forecastDisabledIds.setEnabled(rootId, false)` + 短提示，**不播**长思考，进下一卡。  
   - 思考：插值本卡事件名/叶子/时间/间隔，逐字 30–60ms + 句间停顿；播完自动或点「继续」进下一卡。  
   - 终局：短收尾 +「体验胖宝智能预测」→ 标记本轮引导结束、露出正常预测（含种子 merge 结果）。  
   - 再次进入：若仍有缺口根，再展示（CTA 不永久屏蔽缺口）。

5. **行构建**  
   调整 `smartPredictionRowsProvider`（或包装层）：`history = rangeItems + seedSyntheticRecords`；对仅有种子无真历史的根也能出 row（今日 `buildSmartPredictionRows` 依赖 history 出现过——种子伪记录满足此点）。

## Risks / Trade-offs

- **[Risk] 伪 HistoryRecord 误写入仓储** → 合成只在 provider 内存组装；禁止走 `submitEventAdd`。  
- **[Risk] 种子与真历史双源打架** → 追上即丢；merge 时真历史优先计数，种子仅补缺口根。  
- **[Risk] 根事件过多卡太多** → 产品接受全部 root；可后续加「常用」过滤（本 change 不做）。  
- **[Trade-off] 思考文案「表演感」** → 明确为体验设计，不声称真实 LLM。

## Migration Plan

- 无服务端迁移。升级后本地多一份 seed prefs；回滚删除 store 即可。

## Open Questions

- （已定）无子根：只显示根自身一钮。  
- （已定）跳过：短提示、不播长思考。  
- （默认）CTA 后若再不足：按缺口再排队。
