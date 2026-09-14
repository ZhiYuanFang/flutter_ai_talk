## Why

新用户登录后若很快流失，运维无法从服务端还原「进过哪些页、点过哪些关键控件」，难以判断是入口没被看见，还是功能不被理解/不需要。兄弟仓 `go_ai_talk` 已提供 `POST /device/app/api/client-usage/report` 与 Admin「客户端使用统计」；客户端尚未接入，且上报契约需带运维可读的 `description`。

## What Changes

- 新增登录态静默上报能力：调用 `POST /device/app/api/client-usage/report`，Body 含 `featureId` + `description`；失败丢弃、用户无感知（无 toast）。
- **所有独立产品页展示即上报**（外层主壳 PageView、UCG Tab/发布页、以及全部 GoRouter 可达页，含设置页等；不限 pager 举例页）。
- 动作类埋点：预测卡片开关（on/off + 列表数据序 + 事件类型名）、预测/UCG 列表形态切换、主题色入口点击、主题色切换成功、更换宝宝头像成功。
- 全量登录用户上报；事件设计按新用户体验路径；不因 3 秒服务端限流做本地队列（可接受丢点）。
- **跨仓依赖**：`go_ai_talk` 须接受并持久化/展示 `description`（现网仅 `featureId`）；本变更以契约对齐为前提，Go/Admin 补齐可并行或先行。

## Capabilities

### New Capabilities

- `client-usage-report`: 客户端功能使用上报（静默 HTTP、事件字典、页展示与关键动作埋点）

### Modified Capabilities

- （无）基线 `v2.1.0` 无既有 client-usage 能力；本变更新增独立 capability。

## Impact

- **代码**：新增 `ClientUsageRepository` / 上报辅助与事件常量；挂点于 `UcgHomeShell`、`UcgShell`、Compose、各路由屏、`onForecastToggle`、布局 toggle、`ThemePaletteIconButton` / 主题 apply、`baby_profile_editor` 换头像等。
- **API**：依赖 `POST /device/app/api/client-usage/report`（Bearer）；Body `{ featureId, description }`；featureId/description 勿含 `|`，长度受服务端上限约束。
- **依赖仓**：`go_ai_talk` 须扩展 report + Admin 时间线/功能列表展示 `description`。
- **日志**：若新增 Debug tag，须三联改 `app_debug_log.dart` / `logcat_api_http.ps1` / `app/README.md`。
- **非目标**：MySQL 报表、游客未登录上报、可靠投递队列、计费级防刷。
