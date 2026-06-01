# remember-select-event-in-form 提案

## Why

当前“趋势中心”事件选择在每次进入页面时都回退到目录中的第一个合法叶子事件，无法延续用户上次分析上下文，导致重复操作与体验割裂。需要补齐事件选择记忆能力，使用户再次进入时默认回到上次选择的事件。

## What Changes

- 新增“趋势中心事件选择记忆”：当用户在趋势中心切换事件后，系统持久化最后一次有效选择的事件 ID。
- 调整趋势页初始化选中逻辑：进入页面时优先恢复已记忆且仍合法的叶子事件；若记忆缺失或失效，回退到第一个合法叶子事件。
- 调整目录刷新后的兜底行为：若当前选中项在刷新后不再是合法叶子，按既有规则回退并刷新趋势序列。
- 保持兼容：仅影响趋势中心默认选中行为，不改变事件目录来源、叶子筛选规则、日期范围记忆规则。

## Capabilities

### New Capabilities

- `trends-selected-event-memory`: 趋势中心记忆并恢复上次选中的事件（含失效回退规则）。

### Modified Capabilities

- `trends-leaf-event-picker`: “首次进入默认第一个叶子”语义调整为“优先恢复上次有效选择，否则回退第一个叶子”。

## Impact

- Flutter UI：`app/lib/ui/trends_screen.dart`（初始化与事件切换后的选中逻辑、数据加载触发时机）。
- 本地持久化：`app/lib/config/` 下新增或扩展事件选择记忆存储（`SharedPreferences`）。
- OpenSpec：新增能力规格 `trends-selected-event-memory`，并修改 `trends-leaf-event-picker` 对默认选中场景的需求描述。
