## 1. 数据模型与本地存储

- [x] 1.1 新增 `EventDefinition` 模型与 `tryParseEventColor` / `resolveEventColor(context)`（无色调 → `colorScheme.primary`）
- [x] 1.2 实现 `EventCatalogStore`：`catalog_v1.json` 读写与 `logos/{eventId}` 文件增删
- [x] 1.3 实现远端拉取与按 `id` 对比（`name`、`color`、`logo` URL），触发 JSON 更新与 logo 增量下载
- [x] 1.4 添加占位图 `assets/images/event_placeholder.png` 并在 `pubspec.yaml` 声明

## 2. 全局 Provider 与主页启动

- [x] 2.1 新增 `EventCatalogNotifier` + `eventCatalogProvider`，暴露 `lookupByEventId`
- [x] 2.2 在 `HomeScreen._init` 中：先 `loadFromDisk`，再 `unawaited refreshFromRemote`（登录且 `deviceNo` 就绪）
- [x] 2.3 扩展 `remote_trends_repository` 或 catalog 仓库：解析 `logo`、`color` 字段

## 3. 今日汇总与查找键

- [x] 3.1 `aggregateTodayTotals` 改为按 `eventId` 聚合，保留展示名
- [x] 3.2 `TodayEventTotal` / chip 文案接入目录查找

## 4. 共享 UI 组件

- [x] 4.1 新建 `EventLogo` widget（本地文件 → 占位 asset；Web 分支按需 `Image.network`）
- [x] 4.2 新建 `event_branding.dart` 工具：从 `HistoryRecord` / `eventId` 解析 `EventDefinition`

## 5. 各页面接入

- [x] 5.1 `HomeHistoryTimelineTile`：左侧 logo + 事件色圆点/事件名
- [x] 5.2 `HomeTodaySummaryPanel`：chip 内 logo + 品牌色浅底/边框
- [x] 5.3 `HistoryDetailScreen`：预览/编辑模式事件名区 logo + 品牌色
- [x] 5.4 `TrendsScreen`：下拉项 logo；图表线/柱使用选中事件色；消费全局目录

## 6. 收尾

- [x] 6.1 运行 `openspec validate event-catalog-branding --strict` 并通过
- [x] 6.2 本地冒烟：冷启动离线有缓存、在线更新 logo、无 color 时与主色一致
