## Context

基线 `nextAt = 真lastAt + interval`；过期只影响 UI/`isOverdue`，不追赶。TOD `autoSkip` 可重算亲和，但加法基仍是真 tip。漏记场景需要：过期>2h 时把 **预测点** 当虚拟 tip 再推，且每步重算亲和（昼夜间隔不同）。expect 锚点链用墙钟 `now` + prior 真记录打历史 expect——若套用追赶会污染准确率。

追赶改写 nextAt 后，若 UI 不展示中间 tip，用户会误以为「上次很早却突然预测很远」。需要在竖屏智能预测卡用只读行解释可能漏记；其它表面保持安静。

## Goals / Non-Goals

**Goals:**

- Live 路径：过期>2h → 最多 3 次「tip=预测点 + 重采亲和 + tip+interval」；失败/仍超 → null。
- Widget / 3h / 预测页 / 喂养下一次卡同一 live 追赶结果。
- expect-batch 锚点链关闭追赶。
- lastAt 展示仍真记录。
- 追赶滚过的 tip 保留在预测模型上；竖屏智能预测卡只读展示 `可能漏记：…`。

**Non-Goals:**

- 不写虚拟 tip 进历史。
- 不改预约 nextAt。
- 不改 30min 窗宽本身（只换输入为终显 nextAt）。
- 不在 CRUD body 用 tip cache 代替锚点链。
- 不做漏记 tip 点按补录。
- 不在喂养玻璃卡 / Widget / 接下来3小时 / **横屏**预测卡展示漏记行。

## Decisions

1. **API 形态**  
   - `predictNextForEventKey(..., {bool missedCycleChase = false})`；live/`predictAllUpcoming` 传 `true`；`buildHistoryExpectAnchorPatches` 保持默认 `false`。  
   - 或 live 外包 `applyMissedCycleChase(pred, ...)`，核函数保持纯 tip=真 lastAt——二选一，优先参数开关少分叉。

2. **每步重算**  
   - tip = 当前 nextAt；`_collectAffinityIntervals(records, lastAt: tip)`（tip 仅钟点锚/加法基）；样本&lt;2 → 整根 null。  
   - **禁止** `nextAt = tip + interval₀(真lastAt)`。

3. **与 TOD autoSkip 顺序**  
   - 先完整跑现有 primary/护栏/`autoSkip`（加法基真 lastAt），得候选；再对候选做漏记追赶。

4. **阈值**  
   - `kMissedCycleOverdue = Duration(hours: 2)`；`kMissedCycleMaxRolls = 3`。

5. **null 后果**  
   - UI 无预测态；live 记事不打 expect*；准确率不收该次脏戳；追赶失败无宿主卡时不单独展示 tip。

6. **missedTips 数据**  
   - `EventNextPrediction`（或等价 live 结果）携带有序 `missedTips: List<DateTime>`（0…3）。  
   - 每步追赶开始时，把当时作为 tip 的预测点 append；成功返回时挂上该列表；未追赶则空列表。  
   - live 各表面可同源携带；**仅竖屏智能预测卡消费**。

7. **竖屏卡 UI**  
   - 热态、非预约、非对照 chrome、有非空 `missedTips`、竖屏（非 landscape compact 指标路径）时：在「上一次」行下方、倒计时/预计区块上方，只读一行：  
     `可能漏记：{t1} · {t2} · …`  
   - 每个 ti 用 `formatRelativeCalendarDayAndTime`（或薄封装，今日可省略日词，与「上一次」同源）。  
   - 样式弱于可点「上一次」（无下划线、不可点）。  
   - 横屏 MUST NOT 渲染该行。

## Risks / Trade-offs

- [短间隔连滚 3 次仍远落后 now] → 接受 null，促用户补记真历史。  
- [忘记关 expect 链 chase] → 历史 expect 被墙钟追坏；任务与 analyze 调用点必查。  
- [虚拟 tip 亲和样本变少] → 按失败→null，不强行轻滚。  
- [漏记行与「上一次」并读] → 弱样式 + 明确「可能漏记」前缀，避免被当成可编辑真记录。

## Migration Plan

- 纯客户端算法与 UI；回滚关 `missedCycleChase` / 不渲染 tip 行即可。

## Open Questions

- （无）explore 已锁定：过期 A、重算亲和、上限 3、Widget/3h 同规、expect 链禁用；漏记 tip 仅竖屏智能预测卡只读 `可能漏记：…`，横屏不要。
