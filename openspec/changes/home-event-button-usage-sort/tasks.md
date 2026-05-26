## 1. 本地存储与排序工具

- [x] 1.1 新增 `EventButtonUsageStore`：`event_button_usage_v1` JSON Map， `loadAll` / `increment`
- [x] 1.2 新增 `sortEventsBySubtreeUsage(catalog, nodes, counts)`：子树 score + 稳定降序

## 2. 主页加载与计数写入

- [x] 2.1 `HomeScreen.initState`：异步 load counts，计算并缓存 `_buttonGridOrder`（仅一次 setState）
- [x] 2.2 `_submitEventAdd` 在 `serverId != null` 后 `increment(event.id)`，不触发重排
- [x] 2.3 `HomeButtonEventGrid` 使用缓存排序后的根列表（load 前可暂用 API 序）

## 3. 目录 Picker 排序

- [x] 3.1 `showEventCatalogPickerSheet` 传入 `usageCounts`
- [x] 3.2 每层 `childrenOf` 结果经 `sortEventsBySubtreeUsage` 后再 `ListView`

## 4. 验证

- [x] 4.1 手工：多次成功添加后杀进程重进，横条顺序反映 usage；同会话内顺序不变
- [x] 4.2 手工：文件夹子叶常用时父文件夹靠前；Picker 内子项同规则
- [x] 4.3 `dart analyze` 相关文件无新增告警
