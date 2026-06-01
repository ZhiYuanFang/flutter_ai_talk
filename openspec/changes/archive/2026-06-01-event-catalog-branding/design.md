## Context

- 事件目录接口：`GET /device/history/api/event/options`，`data.list[]` 在既有 `id`、`name` 基础上新增 **`logo`**（图片 URL 字符串）、**`color`**（品牌色字符串，建议 `#RRGGBB` 或网关约定的 hex）。
- 现状：`RemoteTrendsRepository.loadCatalog` 仅映射 `TrendCatalogItem(eventKey, title)`；主页 `HomeScreen._init` 不拉目录；历史/今日/详情/趋势 UI 无 per-event 视觉。
- 历史记录含 `eventId`（`rawPayload`）与 `eventName`；今日汇总按 `eventName` 聚合，需改为以 `eventId` 为主键对齐目录。
- 项目已用 `SharedPreferences`、`path_provider`（APK 下载）；无图片缓存库。

## Goals / Non-Goals

**Goals:**

- 主页启动：同步读本地目录 → 注入全局状态；后台请求 `event/options` 并与缓存对比，有变则更新 JSON + logo 文件。
- 按 `eventId` 解析 logo 本地路径与 `Color`；无 logo 用 assets 占位；无 color 用 **`Theme.of(context).colorScheme.primary`**（主色调）。
- 五处 UI 接入：主页时间轴、今日 chips、历史详情、趋势下拉与图表强调色。
- 趋势页消费同一份全局目录，减少重复解析。

**Non-Goals:**

- 不改历史列表/WS/`chat` 契约；不强制 Web 端 logo 文件缓存（Web 可仅用网络图或占位，见 Risks）。
- 不引入重型图片缓存 SDK；不做 CDN 鉴权以外的自定义协议。
- 不改变服务端 `piece`、历史 `update` 字段。

## Decisions

### 1. 全局状态：`EventCatalogNotifier`（Riverpod）

- `StateNotifier<List<EventDefinition>>` 或 `AsyncValue`，由 `eventCatalogProvider` 暴露。
- `EventDefinition`：`id`（string）、`name`、`logoUrl?`、`colorArgb?`、`localLogoPath?`。
- UI 通过 `ref.watch(eventCatalogProvider)` + `lookupByEventId(int|String)` 取资源；未命中目录时仍展示 `eventName`，logo 占位、color 走主色。

**备选**：仅在 `TrendsRepository` 内缓存 — 否决，主页与详情无法共享。

### 2. 本地存储布局

```
{applicationDocumentsDirectory}/event_catalog/
  catalog_v1.json
  logos/{eventId}.{ext}   # ext 由 URL 或 Content-Type 推断，默认 png
```

- JSON 存完整列表快照（含 `logoUrl`、`localLogoPath`、`color` 字符串副本）。
- 对比更新：将远端列表规范化为 `List<EventDefinition>`，与磁盘 JSON **按 `id` 集合与字段**比较（`name`、`color`、`logoUrl` 任一不同即视为变更）；变更则整表重写并触发 logo 增量下载。
- 删除远端已不存在的事件：移除 JSON 项并 `delete` 对应 logo 文件。

### 3. 启动时序（主页）

```
HomeScreen._init
  ├─ await EventCatalogStore.loadFromDisk() → notifier.state = cached
  └─ unawaited EventCatalogSync.refreshFromRemote()  // 登录且 deviceNo 就绪时
```

- 未登录或无 `deviceNo`：仅加载磁盘缓存（若有），不请求接口。
- 网络失败：保留内存/磁盘旧数据，Toast 可选（与趋势目录空态一致，不阻塞主页）。

### 4. Logo 下载

- 使用现有 `http` 包 GET `logo` URL；写入 `logos/{id}.ext`。
- `logoUrl` 为空或下载失败：不更新 `localLogoPath`；UI 读 `AssetImage('assets/images/event_placeholder.png')`。
- 同一 `id` 的 URL 变更：覆盖写文件并更新路径。

### 5. Color 解析与缺省

- 解析顺序：`Color? tryParseColor(String? raw)` — 支持 `#RGB`、`#RRGGBB`、`#AARRGGBB`、纯 6/8 位 hex；失败视为无色调。
- **无色调**：`resolveEventColor(context, definition)` → `Theme.of(context).colorScheme.primary`。
- 图表（fl_chart）使用解析后的 `Color`，与 Material 主色一致。

### 6. UI 组件

- 新建 `EventLogo`（`localLogoPath` → `Image.file`，否则 `Image.asset` 占位），固定边长 16–20px（时间轴）、chip 内 14–16px。
- 时间轴：圆点/竖线装饰改用事件色；左侧加 logo。
- 今日 chip：左边 logo + 边框或浅底 `color.withValues(alpha: 0.12)`。
- 详情：标题区 logo + 事件名着色。
- 趋势：`DropdownMenuItem` 带 logo；折线/柱 `color` 用事件色。

### 7. 今日汇总键

- `aggregateTodayTotals` 改为 `Map<eventId, ...>`，展示名仍用记录内 `eventName` 或目录 `name`（目录优先）。

### 8. 趋势页

- `TrendsScreen` 初始化时 `ref.read(eventCatalogProvider.notifier).refreshIfStale()` 或 watch provider 构建 catalog；`loadCatalog` 可委托给 catalog sync，避免两套 JSON 解析。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| Web `dart:io` File 不可用 | Web 构建用 `kIsWeb` 分支：占位或 `Image.network(logoUrl)`，不写文件 |
| 行高 34px 加 logo 挤版 | logo 固定宽高，文字 `Expanded` 省略 |
| 历史记录 `eventId` 缺失 | fallback `eventName` 匹配目录 name（唯一时），否则占位+主色 |
| 首次启动无缓存且离线 | 空目录 + 占位图，不崩溃 |
| logo URL 非 HTTPS | 与网关一致；Android 需网络安全配置若混用 HTTP |

## Migration Plan

1. 发版后首次打开主页：磁盘无缓存 → 拉接口 → 写 JSON + logo；旧版用户无迁移成本。
2. 删除 `catalog_v1.json` 即清空品牌缓存（调试）；不影响历史业务数据。

## Open Questions

- `logo` 是否为绝对 URL；若相对路径需拼接 `AppEnv.apiBase`（实现时按联调样例处理）。
- `color` 精确格式以网关文档为准；解析器保留宽松 hex 回退。
