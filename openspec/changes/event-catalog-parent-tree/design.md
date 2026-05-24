## Context

- **现状**：`EventDefinition` 为扁平列表；`HomeButtonEventGrid` 以 `hasValidEventType` 过滤后两行展示；点击直达 `_onEventButtonTap`。趋势页 `_openEventPicker` 展示全量 catalog，默认 `catalog.first`。
- **服务端**：`GET /device/history/api/event/options` 列表项新增 **`parentId`**（父类 ID）；无 `parentId` 表示一级目录。
- **已决产品规则**：
  - 有子节点 → **一律进目录**，即使父节点有 `eventType` 也不得直接 `add`。
  - 根节点：`parentId` 缺失 / `null` / 空串。
  - 子目录 UI：**方案 B**，单 Bottom Sheet 内部导航（面包屑 + 返回），层级无限。
  - 全扁平 legacy：无 `parentId`、全叶子 → 按钮网格行为与现网一致。

## Goals / Non-Goals

**Goals:**

- 解析并持久化 `parentId`；提供 O(n) 建树索引与 root/children/leaf 查询。
- 按钮模式：网格仅根节点；文件夹点击打开方案 B Sheet；叶子点击走既有 `time`/`one`/`number` 流程。
- 趋势页：picker 仅叶子（建议同时要求 `hasValidEventType`）；选中失效时 fallback 到第一个叶子。
- 历史/今日 chips 仍 `lookupEventById`（记录存叶子 id），无需改动。

**Non-Goals:**

- 修改 add/update API、chat、语音/文字输入。
- 在网格或 Sheet 中编辑目录结构。
- 叠多层 `showModalBottomSheet`（不采用方案 A）。

## Decisions

1. **`parentId` 归一化**  
   `fromOptionsMap` / `fromJson`：`null`、空串、仅空白 → 存为 `null`（根）。非空则 trim 后字符串化与 `id` 同规则比较。

2. **树工具 `event_catalog_tree.dart`**  
   纯函数、无 UI：
   - `isRootEvent(e)`
   - `buildChildrenIndex(catalog)` → `Map<String, List<EventDefinition>>`
   - `hasChildren(catalog, id)`
   - `rootEvents(catalog)` — API 顺序
   - `childrenOf(catalog, parentId)`
   - `leafEvents(catalog, {requireValidEventType: true})`  
   orphan（`parentId` 指向不存在 id）：实现时**排除**出 children 索引，可选在 debug 打 log；不自动提升为 root（避免脏数据打乱网格）。

3. **按钮网格过滤**  
   ```text
   gridRoots = rootEvents(catalog)
             .where((e) => hasChildren(catalog, e.id) || e.hasValidEventType)
   ```  
   `splitEventCatalogForButtonGrid` 改为对上述列表对半分行（不再直接用全量 `hasValidEventType`）。

4. **点击路由（`home_screen`）**  
   ```text
   onRootTap(event):
     if hasChildren(event) → showEventCatalogPickerSheet(root: event) → leaf?
     else if hasValidEventType → _onEventButtonTap(event)
     else → 无操作或 Toast
   ```  
   Sheet 返回 `EventDefinition?`（叶子）；非 null 时调用 `_onEventButtonTap(leaf)`。

5. **方案 B：`EventCatalogPickerSheet`**  
   - 单 `showModalBottomSheet`；内部 `StatefulWidget` 维护 `path: List<EventDefinition>`（从用户点击的根/文件夹开始）。
   - **标题**：`path.length == 1` → 仅父名；`> 1` → `A › B › C`（`›` 分隔）。
   - **返回**：`path.length > 1` 时 AppBar leading `←` 执行 `path.removeLast()`；根层无返回（关闭靠下滑或点外部）。
   - **列表**：`childrenOf(catalog, path.last.id)`；`ListTile` + `EventLogo`；有子节点 `trailing: chevron_right`。
   - **点击**：有子 → `path.add(item)`；叶子 → `Navigator.pop(context, item)`。
   - 高度与趋势 picker 对齐（约屏高 2/3）、`showDragHandle: true`。

6. **趋势页**  
   - Picker 数据源：`leafEvents(catalog, requireValidEventType: true)`。
   - `_syncSelection`：translate：默认第一个 leaf；当前 key 非 leaf 或不在 catalog → fallback 第一个 leaf。
   - 可复用 `EventCatalogPickerSheet` 的列表样式，或抽共享 `_EventCatalogList`；趋势为**单层**、无 path 导航。

7. **持久化**  
   `toJson`/`fromJson`/`copyWith`/`catalogSnapshotsEqual`/`parseEventOptionsList` 增加 `parentId`。

8. **Legacy**  
   当所有项 `isRootEvent && !hasChildren && hasValidEventType` 时，`gridRoots` 集合与旧 `valid` 集合相同，无 Sheet 介入。

## Risks / Trade-offs

- **[Risk] 脏数据 parentId 环或 orphan** → 建树时不跟随环；orphan 不进任何 children 列表；根网格仅显式 root。
- **[Risk] 父目录无 logo** → `EventLogo` 已有 fallback，Sheet/网格沿用。
- **[Risk] 叶子无 eventType** → 趋势过滤掉；Sheet 内可展示但点击 Toast「该事件不可记录」或灰显（首版 Toast 即可）。
- **[Trade-off] 文件夹不可直接记录** → 即使配置了 `eventType` 也先进子目录；与产品已决一致。

## Migration Plan

- 发版后：旧本地 catalog 无 `parentId` 字段 → 解析为 `null`，全视为根；与现网行为一致直至服务端下发层级数据。
- 无服务端协议变更；回滚客户端即可恢复扁平逻辑。

## Open Questions

- （已决）方案 B 单 Sheet 内部导航。
- （已决）有子一律进目录；根判定 `parentId` 空。
- （待实现验证）Sheet 根层是否显示「关闭」图标按钮——首版可仅 drag handle + 点外部关闭。
