## Why

用户通过语音、文字或事件按钮成功新增一条历史记录后，往往已把注意力转向新事件，容易忘记列表中仍有其它事件处于进行中计时。当前产品允许不同 eventId 并行计时，但没有任何事后提醒，导致计时长时间悬空。需要在**新增成功后**以非阻断方式提醒用户，并展示具体未结束事件，支持多条时选择性结束。

## What Changes

- 在**新增历史记录成功之后**（按钮 optimistic+API 成功；语音/文字经 WS 落库为新记录），扫描除刚新增记录外的其它进行中计时（`isActiveTimingRecord`）。
- 若存在至少一条其它进行中计时，弹出**屏幕居中**的确认对话框（视觉风格对齐历史编辑 Sheet 的玻璃拟态：`HistoryEditGlassPanel` 等既有 token）。
- 对话框内**逐条列出**未结束的计时事件：事件名、已计时长（实时 `MM:SS` / `HH:MM:SS`）、可选事件图标/色。
- 当存在**多条**其它进行中计时时，用户可通过勾选（或等效多选控件）**选择部分结束**；主操作仅停止已选中的记录。
- 提供「暂不」/关闭：不结束任何计时，新增结果保持不变。
- **不**在新增前拦截或阻断新增流程；与「同 eventId 已在计时中则 Toast 拒绝再次开始」的既有规则并存。
- **不**改变历史行/详情内「停止」按钮的无二次确认行为（`active-timing-stop` 规格不变）。

## Capabilities

### New Capabilities

- `home-active-timing-after-add-reminder`：新增成功后检测其它进行中计时、居中玻璃风提醒对话框、多选部分停止、与三条新增路径（按钮/语音/文字）的触发与去重。

### Modified Capabilities

- （无）本变更不修改 `active-event-timer` 中「列表/详情直接停止无确认」等既有需求；事后提醒为独立能力。

## Impact

- **UI**：新增 `showHomeActiveTimingReminderDialog`（或同类）及列表行组件；复用 `HistoryEditGlassPanel` / `AppVisualTokens` / `resolveEventColor`；`showDialog` 透明 barrier + 居中卡片。
- **逻辑**：`HomeScreen` 在 `_submitEventAdd` 成功、WS 新记录 upsert、fly 动画结束等锚点调用统一检测函数；批量调用现有 `_stopActiveTimer`。
- **状态**：对话框内每秒刷新已选/未选行的已计时长；pending 记录不可选、不可 stop。
- **API**：无新接口；沿用 `updateHistoryRecord` 结束计时。
