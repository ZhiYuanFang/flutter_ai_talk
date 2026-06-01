## Why

底部按钮（`time` / `one` / `number` 及目录二级叶子）创建历史记录后，当前实现等待 **WebSocket** 推送才插入列表并触发飞行动画，网络与 WS 延迟导致「已记录」Toast 与列表/动画反馈脱节。用户选择 **强乐观** 策略：点击后立即出现 pending 行、成功 Toast 体感与飞行动画，并行 `POST add`；成功后用响应 `data.id` 替换 pending id，WS 到达时合并字段而非重复插行或二次动画。

## What Changes

- **强乐观插入**：按钮 tap 后立即向本地历史列表插入一条 `id = pending:<uuid>` 的乐观记录（由 `buildEventAddBody` / mapper 构造展示字段），并触发与 `home-event-record-fly-animation` 一致的飞行动画与「已记录」Toast 体感。
- **并行 add**：后台 `POST /device/history/api/event/add`；成功时解析 envelope **`data.id`**，将 pending id **原地替换** 为服务端 id（保留列表顺序与行内容）。
- **失败回滚**：HTTP/业务失败时 **移除** pending 记录并 Toast 错误信息（与现网 envelope 一致）。
- **WS 对账**：后续 WS `create`/`update` 若 `id` 与列表中已有记录（含已替换的服务端 id）相同，**必须** `upsert` 合并字段，**不得** 再插一行，**不得** 再触发第二次飞行动画。
- **范围**：底部网格全部事件类型（`time` 开始、`one` 一次性、`number` 二级页确认、目录 picker 选中的叶子）均走乐观路径；**语音/文字** `sendCommand` 仍为 **仅 WS**，不做乐观插入。
- **仓储 API**：`addHistoryEvent` 由 `Future<bool>` 改为返回 **服务端 record id**（或失败 sentinel），供 UI 做 id 替换。
- **废止旧规**：取代 `home-button-input-mode` 中 `history-event-add` 的「add 成功后不得用响应 id 插 UI、仅依赖 WS」要求；与 `home-event-record-fly-animation` 协同：乐观插入视为「本地新增 record」，飞行动画在 tap 时触发一次，WS 对账不重复触发。
- **计时停止边缘**：`time` 型乐观 pending 行在 add 完成前，停止计时/详情保存须明确策略（见 design：禁用停止或排队），避免对 `pending:*` 调用 update。

## Capabilities

### New Capabilities

- `home-event-optimistic-add`：按钮路径强乐观插入、pending id、add 响应 id 替换、失败回滚、WS 去重合并、飞行动画触发规则、语音路径排除。

### Modified Capabilities

- `history-event-add`（变更 `home-button-input-mode`）：废止「仅依赖 WS、不得用 add 响应 id」；要求解析并使用 `data.id`。
- `home-event-record-fly`（变更 `home-event-record-fly-animation`）：补充乐观本地新增时的飞行动画触发与 WS 对账时不二次飞行的约束（本变更 specs 中 delta 描述）。

## Impact

- `app/lib/data/feed_repository.dart`、`remote_feed_repository.dart`：`addHistoryEvent` 返回类型与 `data.id` 解析。
- `app/lib/data/history_mapper.dart`：由 add body 构建乐观 `HistoryRecord`（pending id）。
- `app/lib/providers/home_history_notifier.dart`：pending 插入、id 替换、按 id 移除、与 WS upsert 合并语义。
- `app/lib/ui/home_screen.dart`：`_submitEventAdd` / `_onEventButtonTap` 乐观时序、飞行动画 schedule（与 WS 监听去重）。
- 协同只读参考：`home-event-record-fly-animation`（飞行动画、跟底 B+）、`home-button-input-mode`（按钮类型与 add body 映射）。
