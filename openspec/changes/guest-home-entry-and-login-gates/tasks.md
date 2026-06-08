## 1. 游客路由与冷启动

- [x] 1.1 `cold_start_bootstrap.dart`：冷启动目标路由恒为 `/home`
- [x] 1.2 `app_router.dart`：扩展 public 路由（`/home`、`/trends`、`/settings`）；敏感子路由保持登录 redirect
- [ ] 1.3 手工验证：未登录冷启动进喂养主页；`/trends`、`/settings` 可进；`/settings/bind-baby` 被拦

## 2. iOS 网络探测

- [x] 2.1 新增 `bootstrap/ios_network_permission_probe.dart`（iOS only、prefs 标记、GET version/check、5s timeout、静默失败）
- [x] 2.2 `app.dart`：`_beginStartupIfNeeded` 内 `unawaited(IosNetworkPermissionProbe.run())` 与冷启动并行
- [ ] 2.3 手工验证（国行 iOS 真机）：新装首次冷启动触发系统无线数据弹窗（或确认 probe 已发出）

## 3. UCG Dock 登录弹窗门控

- [x] 3.1 `ucg_login_gate.dart`：`requireUcgLogin` 改为玻璃确认弹窗后再 `push('/login')`（对齐 `showGlassConfirmDialog`）
- [x] 3.2 `ucg_shell.dart`：`_onTabTap` 对 index 2/3/4 未登录时弹窗拦截，不切 Tab
- [ ] 3.3 手工验证：游客点消息/我的/发布 → 弹窗 → 去登录；Tab 停留在广场

## 4. 关注 Tab 统一空态

- [x] 4.1 `ucg_square_tab.dart`：抽取关注空态（title/subtitle 固定，无 action）
- [x] 4.2 游客关注 Tab：展示空态，不展示推荐 `_items`，不调 following API
- [x] 4.3 已登录关注 Feed 为空：`_buildBody` 按 `_mode == following` 展示同一空态
- [ ] 4.4 手工验证：游客/已登录空关注文案一致；推荐 Tab 空列表仍用原「暂无动态」文案

## 6. 游客事件目录

- [x] 6.1 `event_catalog_notifier` / `event_catalog_sync`：游客匿名拉取 `GET /device/history/api/event/options`（`withAuthorization: false`）
- [x] 6.2 冷启动未登录时旁路 `refreshFromRemote`，供趋势页等使用

## 5. 回归

- [ ] 5.1 游客：推荐流浏览、帖子详情、他人主页可读；点赞/评论/关注按钮触发登录弹窗
- [x] 5.2 喂养：未登录展示登录引导空态（同未绑定宝宝画廊样式）；含左滑逛广场 footnote；语音/发送仍弹窗拦截
- [ ] 5.3 已登录：Dock 消息/我的/发布行为正常；关注有数据时列表正常
