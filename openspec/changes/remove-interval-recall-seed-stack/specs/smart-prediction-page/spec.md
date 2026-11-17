## ADDED Requirements

### Requirement: Hot prediction cards MUST NOT offer interval-recall fill

On hot-state (non-demo) smart prediction event cards, the client MUST NOT render「补充大概多久一次」or any control that opens the interval-recall seed sheet. Cards that lack affinity `nextAt` MUST follow affinity-progress requirements instead of interval-seed countdown. 「补充上一次」(when `lastAt` is null) and appointment「补充下次」MAY remain. 热态预测卡 MUST NOT 渲染间隔回忆 CTA；无亲和 nextAt MUST 走亲和进度；「补充上一次」与预约「补充下次」MAY 保留。

#### Scenario: 样本不足无间隔钮

- **WHEN** 非预约热态卡 `forecastEnabled`、有真 `lastAt`、无亲和预测
- **THEN** 卡上 MUST NOT 出现「补充大概多久一次」
- **AND** MUST NOT 出现调间隔入口
