## 1. 模型与树工具

- [x] 1.1 `EventDefinition` 增加 `parentId`；`fromOptionsMap` / `fromJson` / `toJson` / `copyWith` 对齐（空串归一化为 null）
- [x] 1.2 `parseEventOptionsList` 与 `catalogSnapshotsEqual` 纳入 `parentId`
- [x] 1.3 新建 `event_catalog_tree.dart`：`isRootEvent`、`buildChildrenIndex`、`hasChildren`、`rootEvents`、`childrenOf`、`leafEvents`

## 2. 方案 B 选择 Sheet

- [x] 2.1 新建 `EventCatalogPickerSheet`（或 `showEventCatalogPickerSheet`）：单 Bottom Sheet、内部 `path` 栈、面包屑标题、返回上一级
- [x] 2.2 列表项：`EventLogo` + 名称；有子节点 `chevron_right`；点文件夹入栈、点叶子 `pop(EventDefinition)`
- [x] 2.3 叶子无合法 `eventType` 时 Toast 或禁用（与 design 一致）

## 3. 按钮模式集成

- [x] 3.1 `splitEventCatalogForButtonGrid` 改为基于 `rootEvents` 且 `hasChildren || hasValidEventType` 过滤
- [x] 3.2 `home_screen` 点击分支：有子 → Sheet → 叶子后 `_onEventButtonTap`；无子 → 直接 `_onEventButtonTap`
- [x] 3.3 验证 flat legacy：全无 `parentId` 时网格与点击路径与现网一致

## 4. 趋势页

- [x] 4.1 `_openEventPicker` 数据源改为 `leafEvents(..., requireValidEventType: true)`
- [x] 4.2 `_syncSelection`：默认与 fallback 使用第一个合法叶子；父节点或失效 id 自动纠正
- [x] 4.3 目录刷新后选中仍有效时序列加载行为不变

## 5. 验证

- [x] 5.1 多级目录：网格仅根 → Sheet 内多层导航 → 叶子 add 成功
- [x] 5.2 有子父节点带 `eventType`：点击仅进 Sheet，不 add
- [x] 5.3 趋势页：父级不出现；叶子可选；默认选中第一个叶子
- [x] 5.4 `dart analyze` 通过变更文件
