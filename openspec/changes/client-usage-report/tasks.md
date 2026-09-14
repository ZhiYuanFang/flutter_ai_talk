## 1. 跨仓契约确认

- [x] 1.1 确认 `go_ai_talk` 已接受 Body `description`（或并行补齐 report 校验、时间线存储、Admin 功能列表/时间线展示描述）；更新/对照其 runbook
- [x] 1.2 本仓 README 或注释中记录契约：`featureId` + `description`、禁止 `|`、须 Bearer、失败可丢、3s 限流可丢点

## 2. 上报基础设施

- [x] 2.1 新增 `ClientUsageRepository`（或等价）：`authorizedApiClient` → `POST /device/app/api/client-usage/report`；校验/截断 featureId 与 description；禁止 `|`
- [x] 2.2 失败路径静默：catch 后不 toast、不向 UI rethrow；可选 `AppDebugLog`（若新增 tag 则三联改 `app_debug_log.dart` / `logcat_api_http.ps1` / `app/README.md`）
- [x] 2.3 提供 `unawaited` 友好的 `report(featureId, description)` / 字典辅助方法；未登录直接 no-op
- [x] 2.4 集中事件字典（稳定 featureId + 默认中文 description）；动态描述由调用方格式化

## 3. 页展示埋点

- [x] 3.1 `UcgHomeShell`：`onPageChanged` 上报喂养/预测/UCG 壳展示；冷启落在预测页首帧补报
- [x] 3.2 `UcgShell`：Tab 切换上报广场/消息/我的展示
- [x] 3.3 `UcgComposeScreen`（或打开处）：发布页展示上报
- [x] 3.4 设置页 `/settings` 展示上报
- [x] 3.5 其余 GoRouter 产品页展示上报（至少：绑宝宝、宝宝资料、反馈、改密、AI 分析 Hub、喂养分析、成长轨迹、值得留意、开通中心、邀请码说明、VIP、趋势、小组件秀、陪伴；按路由表扫漏）

## 4. 动作埋点

- [x] 4.1 预测开关：在真实 `onForecastToggle` 成功路径上报 on/off；description 含顺序（`rows` 下标+1）与事件显示名（无则 eventId）；骨架不报
- [x] 4.2 预测页列表/瀑布切换成功后上报
- [x] 4.3 UCG 广场布局切换成功后上报
- [x] 4.4 `ThemePaletteIconButton` 点击上报入口；主题 apply/clear 成功上报成功事件（description 含主题信息）
- [x] 4.5 宝宝头像落盘成功上报；取消/失败不报成功

## 5. 验收

- [x] 5.1 登录后手工走：主壳滑动、UCG Tab、进设置、开预测开关、切布局、开调色盘并换色、换头像；Admin 时间线可见对应 featureId + 中文描述
- [x] 5.2 确认未登录不请求；断网/限流时 UI 无报错提示
- [x] 5.3 不新增 `**/test/**` 测试文件（除非用户另行要求）
