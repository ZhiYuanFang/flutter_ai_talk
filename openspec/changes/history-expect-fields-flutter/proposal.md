## Why

预测准确度需要「当时预报 vs 实际」可审计数据。twin **`go_ai_talk` / `history-expect-fields-go` 已完成**：表可空三列、add 落库、update/end-latest **不写** expect 列、list/WS/缓存回传。本仓补充客户端：在 **add** 打戳并透传保留。

## What Changes

- `buildEventAddBody` 支持可选 JSON：`expectStartTime` / `expectEndTime`（unix **秒**，与 Go `*int64`）、`expectAmount`（**浮点** `double`，与 Go `*float64`；MUST NOT 当 int 截断）。
- **仅 add** 打戳：`expectStartTime` ← 当时 `nextAt`（**过期仍打**）；有 duration expect → `expectEndTime = start + durationSec`；有 amount expect → `expectAmount`；无对应维则 **省略键**（对齐 Go `omitempty` / 仅非 nil 才 INSERT）。
- `buildEventUpdateBody`、计时 stop、编辑保存、任何 update **MUST NOT** 传 expect*（Go UPDATE 本就不写这些列；客户端也不应误带）。
- 本地 `rawPayload` 透传 list/WS 带回的 expect*；磁盘 equality 纳入三键，避免旧行覆盖。
- 准确度只认有可用 expect* 的行，**不重放**（柱图 UI 另 change）。
- **非目标**：不改 Go；不做准确度柱图；不改 UCG flag。

## Capabilities

### New Capabilities

- `history-expect-fields`：客户端 add 打戳、update/stop 不传、本地透传与准确度消费约束。

### Modified Capabilities

- （无）

## Impact

- `history_mapper.dart`、`event_add_actions` / `submitEventAdd` 等 add 链、`home_history_store` equality、WS upsert。
- **依赖状态**：Go twin 已交付；本 change 可独立 apply 联调。
