## Context

`_PredictAccuracyChartPane` 在 `hasAny == false` 时居中「暂无预测对照」。真路径已有柱图 + 点柱小结。产品要求：每张无样本竖卡用示例演示「准确率对照」含义；卡上半倒计时/上一次不动；示例禁止出现下次/上一次。

## Goals / Non-Goals

**Goals:**

- 无真样本 → 示例柱（高低起伏）+ 居中「示例」说明 + 可点进示例小结。
- 有真样本 → 仅真数据路径不变。
- 示例与 `prediction_demo_skeleton`、history/pending 隔离。

**Non-Goals:**

- 藏卡上半倒计时/上一次；改命中阈值 1800s；横滑/瀑布；全局只教一次的开关。

## Decisions

1. **触发**：近窗内对该根 `predictAccuracySamplesFromHistory` 得到的日 % 全为 null（与现 `hasAny` 相反）时进入示例态。每张满足条件的卡都显示。

2. **示例柱**：按 `eventId`（及可选固定盐）稳定生成 7（或与 `pastDaysBeforeToday+1` 同长）个 45–95 的整数 %，相邻日故意高低差 ≥15，避免一条平线。全部日视为「有样本」可点。

3. **示例小结**：点柱后同卡替换；每行「准/偏」+「预计 HH:mm → 实际 HH:mm」；用固定偏移构造命中/偏离各至少一条（若该日只演示一条则随机准或偏但全局多日有两种）。顶栏带「示例」；返回「近7日」回示例柱。

4. **文案**：柱图上方居中小字默认「示例数据」或「以下为示例，说明预测准不准」；MUST NOT 在图区写下次/上一次。

5. **隔离**：示例结构仅内存 UI 模型；MUST NOT 写入 `HistoryRecord`、MUST NOT 进 `predictDailyAccuracyPercents` 真路径入参、MUST NOT 打 pending。

6. **与整卡 InkWell**：保持图区吞掉点击，示例点柱不触发加事件。

## Risks / Trade-offs

- [用户把示例当真实准确率] → 持续「示例」标注；有真样本立即切真数据。  
- [与 demo skeleton 混淆] → 文档/代码注释区分：skeleton=无预测整卡；本处=有预测无对照戳。  
- [假 % 过于真实] → 文案必须可见；不做持久化。

## Migration Plan

1. 改 `_PredictAccuracyChartPane` 空态与示例数据工厂。  
2. 真机：无 expect 戳的卡见示例；有戳后消失。  
3. 回滚：恢复「暂无预测对照」即可。

## Open Questions

- （已定）每张无样本卡都显示；假 % 有高有低；卡上半倒计时/上一次保留。
