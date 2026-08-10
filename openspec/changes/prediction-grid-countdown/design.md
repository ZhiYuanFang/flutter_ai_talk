## Context

网格卡（`compact: true`）当前：标题行 + `formatPredictionGridRelative` 短文案 + `_LookbackChart`（近 3 日）。页级已有 `predictionClockProvider`（每秒 `DateTime.now()`）。列表卡不变。

## Goals / Non-Goals

**Goals:**

- 网格主区改为指向 `nextAt` 的倒计时显示；未超时无上方短文案。
- 超时：时钟固定 `00:00:00`，保留 overdue 短文案。
- 每秒刷新依赖既有 clock provider。

**Non-Goals:**

- 不改列表折线、推演开关、tip、care-alert、小组件。
- 不改 `nextAt` 预测算法与 range 拉取。
- 不新建测试文件。

## Decisions

1. **格式始终三节 `H…:MM:SS`**  
   小时可超过 24（如 `36:00:00`），分钟/秒两位补零；未超时用 `nextAt.difference(now)`，超时强制零时长文案 `00:00:00`。  
   **备选**：&lt;1h 用 `MM:SS`——拒绝，产品要求时:分:秒。

2. **超时文案复用 `formatPredictionGridRelative(..., overdue: true)`**  
   未超时不再调用该函数作网格上方行。

3. **`compact` 分支内替换图表槽**  
   推演开启且可预测时渲染倒计时（及仅超时的短文案）；推演关仍置灰且无主区。加载中若网格不再依赖 chart points，可不显示「正在加载中」于倒计时槽（倒计时仅需 `nextAt`）；若整页仍在算行则可保留页级 loading 语义——网格卡本身在 `pred != null` 时直接显示倒计时。

4. **刷新**  
   屏幕已 `watch(predictionClockProvider)` 驱动 `now` 时，倒计时随 rebuild 更新；若未 watch 则补上。

## Risks / Trade-offs

- [窄卡大号数字溢出] → 用略小字号或 `FittedBox`。  
- [与 layout-grid「三日折线」规格冲突] → 本 change REMOVED/替代该网格折线要求；归档时以本 delta 为准。

## Migration Plan

- 纯 UI；热重载即可。无需数据迁移。

## Open Questions

- （无）短文案与超时方案 B 已确认；≥24h 采用可涨小时。
