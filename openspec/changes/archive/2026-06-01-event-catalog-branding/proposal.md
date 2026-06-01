## Why

当前各页面仅以事件名字符串展示，色调统一为主题色，辨识度低。服务端已在 `GET /device/history/api/event/options` 的列表项上增加 `logo` 与 `color` 字段；客户端需缓存目录与 logo 文件，在主页启动时同步，并在历史、今日汇总、详情、趋势等场景按事件展示图标与品牌色，提升扫读效率。

## What Changes

- 扩展事件目录模型：解析 `id`、`name`、`logo`（URL）、`color`（色值）；缺省 logo 用占位图，缺省 color 跟随当前主色调（`Theme.colorScheme.primary` 或产品约定的主色语义）。
- 主页启动：先从本地缓存加载事件目录为全局可读状态；再请求 `event/options`，与缓存对比，有变化则更新 JSON 元数据并下载/清理 logo 本地文件。
- Logo 以文件形式保存在应用文档目录（按 `eventId` 命名）；元数据 JSON 记录 `logoUrl` 与 `localLogoPath`。
- 所有事件相关展示接入品牌资源：主页历史时间轴、今日汇总 chips、历史详情（预览/编辑）、趋势中心（下拉与图表强调色）。
- 今日汇总聚合键改为优先 `eventId`（与目录对齐），展示时解析 logo/color。
- 趋势中心复用全局事件目录，避免与主页两套独立拉取逻辑（可保留进入趋势页时的刷新触发）。

## Capabilities

### New Capabilities

- `event-catalog-cache`：事件目录本地缓存、启动加载、远端对比更新、logo 文件下载与全局 Provider/仓库契约。
- `event-branded-ui`：历史/今日/详情/趋势等 UI 展示事件 logo 与色调的规则与缺省行为。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线）趋势与主页相关历史行为通过上述新能力规格描述；实现时对齐既有 `event/options` 消费点（`remote_trends_repository`、主页 `_init`）。

## Impact

- `app/lib/data/`：事件目录模型、本地 Store、远端同步仓库；扩展 `remote_trends_repository` 或新建 `event_catalog_repository`
- `app/lib/providers/`：`EventCatalogNotifier`（或等价 Riverpod 全局状态）
- `app/lib/ui/home_screen.dart`、`home_history_timeline_tile.dart`、`home_today_summary_panel.dart`、`history_detail_screen.dart`、`trends_screen.dart`
- `app/lib/data/history_record_metric.dart`（今日汇总按 eventId）
- 资源：`assets/` 占位图；`pubspec.yaml` 声明；可能新增 `http` 下载逻辑（已有依赖）
- API：`GET /device/history/api/event/options` 列表项字段 `logo`、`color`（camelCase，与网关一致）
