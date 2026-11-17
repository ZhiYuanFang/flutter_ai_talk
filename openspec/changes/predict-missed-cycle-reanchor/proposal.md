## Why

用户漏记上一场喂养时，live `nextAt` 会长期钉在过期预测上（或仍从真 `lastAt` 推出过期点），后续展示与记录打戳都跟着漏记周期走，准确度与体验双降。需要在「过期超过 2 小时」时用上一预测点作虚拟 tip、重算钟点亲和，静默追赶下一场；追赶失败则放弃预测，避免脏 expect。

追赶成功后，卡上只见「真 lastAt 很早、下次很远」，用户不知道中间系统推过场次。需要在**竖屏智能预测卡**上只读展示中途跳过的预测时刻，解释「可能漏记」，避免误判算法突变。

## What Changes

- Live 非预约亲和预测：常规 `nextAt₀ = 真lastAt + interval`（含既有 TOD 护栏/`autoSkip`）算完后，若 `now − nextAt > 2h`，最多 **3** 步漏记追赶：每步以当前预测点为 tip，**重采亲和**得 interval，`nextAt = tip + interval`；禁止复用真 lastAt 那一轮 interval 硬加。
- 满 3 步仍 `now − nextAt > 2h`，或任一步亲和样本不足 → **无 nextAt**（不可预测）。
- 展示 `lastAt` 仍为真记录；终显 `nextAt`（或 null）为准；30 分钟喂养 A/B/C 只作用于终显 nextAt。
- 无 nextAt：喂养页不下一次预测卡；活记录路径不打 `expectStartTime` 等 expect*。
- 智能预测页、接下来3小时、桌面 Widget：**同一追赶规则**。
- **EXPECT 锚点链禁用**：`buildHistoryExpectAnchorPatches` / 中间插入重算上传 **不得** 跑漏记追赶（避免用墙钟 now 把历史 expect 追到现在或大面积 null）。
- **漏记 tip 保留**：追赶每步滚过的虚拟 tip MUST 挂在 live 预测结果上（如 `missedTips`）；不得写入喂养历史。
- **竖屏智能预测卡只读行**：有非空 tip 列表时，在「上一次」与倒计时之间展示 `可能漏记：{相对自然日时分} · …`；**横屏不展示**；喂养玻璃卡 / Widget / 3h **不展示**；不可点补录。

## Capabilities

### New Capabilities

- `predict-missed-cycle-reanchor`：live 漏记追赶触发、重算亲和、上限 3、失败 null、与 expect 链隔离、跨表面一致；追赶 tip 列表供竖屏预测卡只读展示。

### Modified Capabilities

- `event-interval-prediction`：live 消费者在得出候选 nextAt 后 MUST 可经漏记追赶改写或清空；公式基线仍以真 lastAt 起步。
- `home-next-predict-glass-card`：无终显 nextAt 时 MUST NOT 展示下一次预测卡（玻璃卡仍不展示漏记 tip 行）。
- `predict-post-mutation-scheduler`：锚点链 expect 重算 MUST NOT 启用漏记追赶。
- `smart-prediction-page`：竖屏热态卡 MUST 只读展示追赶留下的漏记 tip；横屏 MUST NOT。

## Impact

- 核：`event_next_predictor.dart`（`predictNextForEventKey` / `predictAllUpcoming` 增加 live 开关或外包 chase；追赶成功时带上 `missedTips`）。
- 调用方：智能预测 rows、3h、Widget、喂养下一次卡；`history_expect_anchor_chain.dart` 显式关闭 chase。
- UI：仅 `smart_prediction_screen` 竖屏热态卡读 `missedTips` 渲染只读行。
- 打戳：live 无 pred 时不写 expect*（既有 `HistoryExpectStamp.fromPrediction`）。
- 无新 HTTP/原生；Android N/A。
