## Context

- **现状**：`HomeButtonEventGrid` 通过 `buttonGridRowEvents` → `buttonGridRootEvents` 取目录顺序；`EventCatalogPickerSheet` 每层用 `childrenOf` 保持 API 序。已有 `EventNumberMemoryStore`（按 eventId 记 number 用量）与 `HomeInputChannelStore`（SharedPreferences 模式）。
- **入口**：按钮添加经 `_onEventGridTap` → `_onEventButtonTap` → `_submitEventAdd`；成功以 `addHistoryEvent` 返回非空 `serverId` 为准。
- **约束**：用户要求 **不** 按 deviceNo 隔离；**仅 `HomeScreen.initState`** 重排（非 RouteAware）；本会话内不因新计数改变横条顺序。

## Goals / Non-Goals

**Goals:**

- 成功添加后对 **实际落库的 eventId** +1 并持久化。
- 底部根按钮按 **子树用量总分** 稳定降序。
- Picker 每一层同级子项同样规则排序。
- `initState` 异步 load counts，缓存排序结果供 Grid/Picker 使用。

**Non-Goals:**

- 语音/文字路径计数、服务端同步、按宝宝分桶。
- 从趋势/设置 pop 回主页时重排（Home 未 destroy 则顺序不变）。
- 会话内实时重排、清除/导出用量统计 UI。

## Decisions

### 1. 存储 — `EventButtonUsageStore`

- **Key**：`event_button_usage_v1` → JSON `Map<String, int>`（eventId → count）。
- **API**：`loadAll()`、`increment(eventId)`（读-改-写，+1）。
- **理由**：与 `EventNumberMemoryStore` 一致；单 key JSON 便于整表排序时一次读取。

### 2. 子树评分

```
subtreeScore(id) = ownCount(id) + Σ subtreeScore(每个直接子节点 id)
```

- 对 `catalog` 构建 parent→children 索引（复用 `buildChildrenIndex` / `childrenOf` 逻辑）。
- Memoization 按 `eventId` 缓存，避免重复遍历。
- **文件夹**在横条/Picker 中用 `subtreeScore` 比较；**叶子**仅有 ownCount。

### 3. 稳定排序

- 比较：`subtreeScore(b) - subtreeScore(a)`；若相等，保留 **catalog 原索引**（stable sort）。
- count 为 0 的项排在有 usage 的之后（score 0 组内仍 API 序）。

### 4. 写入点

- **`_submitEventAdd`**：`serverId != null` 后 `EventButtonUsageStore.increment(event.id)`（`event` 为最终落库定义，含 Picker 叶子）。
- **不** 在 `_onEventGridTap` 仅打开 Picker 时计数。

### 5. 读取与重排时机 — 仅 initState

- `HomeScreen` 增加 `Map<String, int>? _eventUsageCounts`（或 empty map 表示已 load）。
- `initState` → `unawaited(_loadEventUsageCounts())`：prefs load 完成后 `setState`。
- **Grid**：`HomeButtonEventGrid` 接收 `usageCounts`；若 null 则暂用 API 序（load 完成前），load 后应用排序。
- **Picker**：`showEventCatalogPickerSheet` 增加可选 `usageCounts` 参数；Sheet 内对每层 `childrenOf` 结果排序。
- **本会话**：increment 只写 prefs，**不** 触发 Grid rebuild 排序（counts 可变但 `_sortedRoots` 只在 initState 算一次 — 用单独 `List<EventDefinition>? _buttonGridOrder` 在 load 时固定）。

```
initState
  → load counts from prefs
  → compute sorted roots once → _buttonGridOrder
  → setState

submit success
  → increment prefs only (no resort)

下次冷启动 / Home 重建
  → initState 再次 load → 新顺序
```

### 6. 模块划分

| 模块 | 职责 |
|------|------|
| `event_button_usage_store.dart` | prefs 读写 |
| `event_catalog_usage_sort.dart` | `subtreeScore` + `sortEventsByUsage` |
| `home_screen.dart` | load + cache order + increment |
| `home_button_event_grid.dart` | 接受预排序 list 或 catalog+counts |
| `event_catalog_picker_sheet.dart` | 每层 children 排序 |

**选择**：排序 util 放 `data/` 或 `config/` 旁，依赖 `EventDefinition` + catalog，不依赖 UI。

## Risks / Trade-offs

- **[Risk] initState load 完成前短暂 API 序** → 可接受；prefs 通常 <10ms，或 Grid 在 counts null 时不渲染按钮区（过重则保持现状）。
- **[Risk] 目录 id 变更导致旧 count 残留** → 排序忽略不在 catalog 的 id；可选惰性不写回清理。
- **[Risk] 用户期望从设置返回即重排** → 已明确 **仅 initState**；需在 release note 说明需重启或 re-enter 路由重建 Home。
- **[Trade-off] 文件夹 score 含子孙** → 常用子叶会把父文件夹顶到前面，符合「喂养类常用」预期。

## Migration Plan

- 纯客户端；首次无 prefs 时等价 API 序。回滚即移除 sort 与 increment。

## Open Questions

- （已决）重排 **仅 initState**，不用 RouteAware。
- （已决）不按 deviceNo 隔离。
