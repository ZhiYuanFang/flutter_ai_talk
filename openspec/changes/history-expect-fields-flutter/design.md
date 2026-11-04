## Context

`history-expect-fields-go` 已在 `go_ai_talk` 落地。本 change 对齐其冻结契约并实现 Flutter 打戳与缓存。产品规则不变：过期 nextAt 仍打；仅 add；stop/update 不改；不重放。

## Goals / Non-Goals

**Goals:**

- Add body 与 Go `DeviceHistoryEventAddReq` 对齐的可选三字段。
- 从 `EventNextPrediction` 打戳；无维省略键。
- Update/stop 永不传 expect*。
- rawPayload / 磁盘 / WS 保留服务端回传。

**Non-Goals:**

- Go/DB（已完成）。
- 准确度柱图 UI、UGC 隐藏。

## Decisions

1. **与 Go 契约对齐（冻结）**  
   | JSON | Go | 含义 |
   |---|---|---|
   | `expectStartTime` | `*int64` omitempty | unix 秒 |
   | `expectEndTime` | `*int64` omitempty | unix 秒 |
   | `expectAmount` | `*float64` omitempty | 浮点用量 |

2. **打戳映射**  
   - `nextAt`（int 秒）→ `expectStartTime`（含过期）。  
   - `expectDurationSec` 有值且 start 有值 → `expectEndTime = expectStartTime + expectDurationSec`。  
   - `expectAmount`（Dart `double?`）→ JSON number；**禁止** `toInt()` 截断。  
   - 无值：**不要**写 `0` 占位（避免与「预计为 0」或 Go 指针语义混淆）；直接省略。

3. **注入点**  
   `buildEventAddBody` 增加可选参数（或 `ExpectStamp` 小对象）；所有 add 入口传入；`buildEventUpdateBody` / `stopActiveTimingRecord` 不传。

4. **缓存**  
   equality 含 `expectStartTime` / `expectEndTime` / `expectAmount`（rawPayload 取值）。整包 server map → rawPayload 即可透传。

5. **联调**  
   Go 已就绪：add 带字段 → list/WS 应回传；update 后 expect* 仍在。

## Risks / Trade-offs

- [误传 update 带 expect*] → Go 忽略且不写列，无抹库；仍 SHOULD NOT 传以免误导。  
- [amount 用 int] → 与 Go 浮点不一致，小数丢失；MUST 用 double。  
- [无 pred 不打戳] → 准确度样本偏少，可接受。

## Migration Plan

1. 发 Flutter；与已上线/待发 Go 联调。  
2. 回滚：add body 停传 expect*。

## Open Questions

- 无（已与 Go 实现对齐）。
