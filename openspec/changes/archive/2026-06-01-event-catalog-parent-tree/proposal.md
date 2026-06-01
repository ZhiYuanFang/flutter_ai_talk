## Why

服务端事件目录 `GET /device/history/api/event/options` 已增加 **`parentId`**，用于表达多级分类。客户端仍按扁平列表展示与筛选，按钮模式无法按「一级目录 → 子项」逐级选择，趋势页也会把仅作目录的父级事件当作可统计维度。需要在不破坏现有全扁平目录兼容的前提下，支持树形导航与叶子级趋势选择。

## What Changes

- **`EventDefinition`** 增加 **`parentId`**（可选）；解析时 `null` / 空串 / 缺失均视为一级目录（根节点）。
- 新增 **`event_catalog_tree`** 工具：根节点、子节点、是否有子节点、叶子节点集合；保持 API 返回顺序。
- **按钮模式网格**：仅展示根节点（`hasChildren` 或可直接记录的叶子根）；**有子节点一律进目录**，不得直接 `add`。
- **子目录选择**：采用 **方案 B**——**单个** Bottom Sheet，内部面包屑/返回栈无限层级导航；选中叶子后关闭 Sheet，沿用现有 `time` / `one` / `number` 记录流程。
- **趋势页事件选择**：仅展示 **叶子节点**（目录中无任何子项的事件）；不展示有子目录的父级事件；默认选中与 fallback 同步改为第一个叶子。
- **Legacy 兼容**：若全部事件均无 `parentId` 且均为叶子、且具备合法 `eventType`，按钮网格与点击行为与当前版本一致。
- 本地 catalog JSON 持久化与 `catalogSnapshotsEqual` 纳入 **`parentId`**。

## Capabilities

### New Capabilities

- `event-catalog-parent-id`：`parentId` 解析、持久化、树索引与 root/leaf/children 纯函数。
- `home-button-event-tree-nav`：按钮模式根网格、方案 B 单 Sheet 内部导航、叶子选中后衔接既有 add 分支。
- `trends-leaf-event-picker`：趋势页事件选择器仅叶子列表及选中态同步。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线；与 `home-button-input-mode` 归档规格在行为上为网格数据源与点击入口的扩展，本变更以新增 capability 规格完整描述。）

## Impact

- `app/lib/data/event_definition.dart`、`event_catalog_store.dart`：模型与快照对比。
- `app/lib/data/event_catalog_tree.dart`（新）：树工具。
- `app/lib/ui/event_catalog_picker_sheet.dart`（新）：方案 B 可复用 Sheet。
- `app/lib/ui/home_button_event_grid.dart`、`home_screen.dart`：根节点过滤与 drill-down。
- `app/lib/ui/trends_screen.dart`：叶子过滤与 `_syncSelection`。
- **Out of scope**：`event/add` / `event/update` 契约、历史行展示、语音/文字输入、number 二级页 UI。
