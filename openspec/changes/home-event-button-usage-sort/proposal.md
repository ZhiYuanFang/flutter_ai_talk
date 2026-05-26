## Why

底部按钮模式的事件顺序目前固定为目录 API 返回序，无法适应不同家长的高频操作；常用事件往往排在横条右侧需反复滑动。需要在本地记录「成功添加」次数，并在再次进入主页时按使用频率重排，减少操作路径。

## What Changes

- **本地用量计数**：按钮模式（含目录 Picker 选中的叶子）在 **成功添加历史记录**（`addHistoryEvent` 返回有效 `serverId`）后，对该 **eventId** 计数 +1；失败、Toast 拦截（如已在计时中）、取消 Sheet 不计数。
- **子树累计排序**：底部横条一级按钮按 **子树用量总分**（自身 count + 所有后代 count）降序；同分保持目录原序（稳定排序）。
- **Picker 内排序**：打开父级文件夹后，同级子项同样按子树/叶子用量规则降序。
- **重排时机**：仅在 **`HomeScreen.initState`** 时从 SharedPreferences 加载 counts 并计算排序；**本会话内**成功添加后 **不得** 即时重排底部横条（避免按钮跳动）；从趋势/设置 pop 回主页 **不** 额外重排（Home 未重建时顺序不变）。
- **存储范围**：本机全局一份计数，**不** 按 `deviceNo`/宝宝隔离。
- **Out of scope**：语音/文字添加计数、服务端同步、按宝宝分桶、RouteAware 返回重排。

## Capabilities

### New Capabilities

- `home-event-button-usage-sort`：本地成功添加计数、子树评分、底部横条与目录 Picker 按用量排序及 initState 重排策略。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线）与 `home-button-input-mode`、`event-catalog-parent-tree` 兼容：仅改变按钮/Picker 展示顺序，不改变添加语义与目录结构。

## Impact

- 新增 `EventButtonUsageStore`（SharedPreferences，参考 `EventNumberMemoryStore`）。
- `app/lib/data/event_catalog_tree.dart` 或独立 util：子树 score + 稳定排序。
- `app/lib/ui/home_screen.dart`：initState 加载排序；`_submitEventAdd` 成功 increment。
- `app/lib/ui/home_button_event_grid.dart`：使用缓存排序后的根列表。
- `app/lib/ui/event_catalog_picker_sheet.dart`：传入 counts，每层 `childrenOf` 排序。
- 无 API、依赖变更。
