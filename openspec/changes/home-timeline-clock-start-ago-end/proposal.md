## Why

喂养主页历史日分块已按 `startTime` 归日，但时间轴左列 `HH:mm` 对已结束计时仍取 `endTime`，出现「归昨天、钟点却是今早醒来」的错位。产品选择方案 **B**：只改左列钟点为开始时刻，相对「x分前」标签仍相对结束时刻（长睡醒后仍像「刚刚」）。

## What Changes

- 主页历史时间轴**左列** `HH:mm` MUST 取记录开始时刻（与日键同源：`startTime`，缺失回退既有规则）。
- **相对时间标签**（ago）、「各事件最新」判定、日内排序 MUST 继续使用既有 `historyHomeDisplayInstant`（已结束计时仍为 end）。
- **不**全局把 `historyHomeDisplayInstant` 改为 start（避免 ago / 排序语义跟着变）。
- **不**改预测分桶、日汇总聚合规则（日键已为 start）。
- **不**新建 `**/test/**`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-history-compact-timeline`：左列 `HH:mm` 锚改为 start（与日键同源）。
- `home-history-relative-ago-badge`：明确 ago / 「最新」判定仍用 `historyHomeDisplayInstant`（已结束计时为 end），不得改用左列时钟锚。
- `home-history-date-sections`：跨夜场景下左列与 start 日键一致（不改日键本身）。

## Impact

- 代码：`history_line_format.dart`（拆出左列时钟 helper / 调整 `historyHomeRowDisplay.timeLabel`）；`home_history_scroll.dart` 等仅消费 `timeLabel` 的路径随 helper 生效；ago 路径继续 `historyHomeDisplayInstant`。
- 规格：上述 capability delta；对照基线 `openspec/specs/v2.1.4.md`。
- 无 HTTP / 无原生 / 无预测算法变更。
