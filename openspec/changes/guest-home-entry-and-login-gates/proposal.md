## Why

国行 iOS 新安装 App 需在首次网络访问后才会弹出「无线局域网与蜂窝网络」系统授权；当前冷启动将未登录用户强制导向 `/login`，既偏离 v1.0.1 基线「默认进入主页」与 UCG「推荐可匿名浏览、页内 gate」设计，也使游客无法在授权弹窗出现前通过公开 Feed 自然触发联网。需恢复游客进主页，并在个人信息相关操作时用弹窗引导登录，同时为国行 iOS 增加非阻塞的首次网络探测。

## What Changes

- **冷启动路由**：`ColdStartBootstrap` 无论登录态，冷启动完成后 MUST 导航至 `/home`（不再默认 `/login`）。
- **Router 门禁收窄**：`go_router` redirect 允许未登录访问 `/home`、`/trends`、`/settings`；敏感子路由（如 `/settings/bind-baby`、`/settings/change-password`、`/settings/feedback`）仍要求登录。
- **UCG Dock 门控**：未登录用户点击底部「消息」「我的」「+（发布）」时 MUST 弹出确认对话框引导登录，且 MUST NOT 切换至对应 Tab；确认后 `push('/login')`。
- **关注 Tab 空态**：未登录或已登录但关注 Feed 为空时，展示统一发现引导空态（纯文案、无按钮），且未登录时 MUST NOT 请求 `/feed/following`。
- **iOS 网络探测**：iOS 冷启动并行发起一次无鉴权 GET（复用 `version/check` 或等价轻量接口），不处理响应、不阻塞 Splash；每安装仅探测一次（SharedPreferences 标记）。
- **喂养/UCG 既有页内 gate**：语音、发送、点赞、评论、关注等操作继续沿用或对齐玻璃确认弹窗模式（`showGlassConfirmDialog` / `requireUcgLogin` 升级）。

## Capabilities

### New Capabilities

- `guest-home-routing`：游客冷启动进 `/home`、`go_router` 公开路由与敏感子路由门禁，对齐 v1.0.1「默认进入主页」。
- `ios-network-permission-probe`：国行 iOS 首次安装非阻塞网络探测，触发系统无线数据授权弹窗。

### Modified Capabilities

- `ucg-shell-navigation`：消息/我的/发布 Tab 未登录弹窗拦截（不切 Tab）。
- `ucg-square-feed`：关注 Tab 未登录与空列表统一发现空态，替代登录引导页。

## Impact

- **Affected code**：`app/lib/bootstrap/cold_start_bootstrap.dart`、`app/lib/router/app_router.dart`、`app/lib/app.dart`、`app/lib/ucg/ui/ucg_shell.dart`、`app/lib/ucg/ui/ucg_square_tab.dart`、`app/lib/ucg/ui/ucg_login_gate.dart`；新增 `app/lib/bootstrap/ios_network_permission_probe.dart`。
- **API**：复用现有 `GET /device/app/api/version/check`（无鉴权）；UCG 公开 Feed/详情/他人主页接口行为不变。
- **规格基线**：MODIFIED 对齐 `openspec/specs/v1.0.1.md` 中「默认进入主页」「Splash 仅本地门禁后进入主页」；MODIFIED `add-ucg-module` 的 `ucg-square-feed` 关注 Tab 条款。
- **测试**：国行 iOS 真机验证网络授权弹窗与游客路径；Web/Android 回归路由与 UCG gate。
