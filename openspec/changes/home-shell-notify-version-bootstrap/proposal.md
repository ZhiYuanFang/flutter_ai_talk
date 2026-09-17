## Why

智能预测成为 `/home` 默认着陆页后，notify 维护公告与版本更新弹窗仍挂在喂养页 `HomeScreen._init`。冷启停在预测页时用户可能长时间看不到维护/升级提示；且现网顺序实际是版本先于 notify，与基线「维护优先」不符。需要把启动级弹窗上挪到主壳挂载，并串行执行。

## What Changes

- 将 **notify banner** 与 **版本检查弹窗** 的自动触发从喂养页上挪到 **`UcgHomeShell` 挂载**（进入 `/home` 主壳一次）。
- 启动级弹窗 **串行**：先检测/展示 notify；若弹出则 **await 关闭后** 再检测/展示 version；无 notify 则立刻进入 version。
- **游客** 与已登录用户均 MUST 自动执行 version 检查（设置中心手动「检查更新」保持不变）。
- **resume**、**登录中途**（主壳已挂载期间登录成功）MUST NOT 自动弹 notify，也 MUST NOT 自动弹 version。
- 从 `HomeScreen` 移除 `_runHomeDialogBootstrap` / `_runPostLoginBootstrap` 中的自动弹窗职责（网关/WS 等补全可保留，但不带这两个弹窗）。

## Capabilities

### New Capabilities

- `home-shell-dialog-bootstrap`：主壳启动级弹窗编排（挂载时机、串行队列、排除 resume/登录中途）。

### Modified Capabilities

- `app-notify-banner`：明确触发点为 `UcgHomeShell` 挂载（不依赖喂养页 mount）；与 version 串行且为队首；resume/登录中途不弹。
- `app-versioning`：主壳挂载后自动 version 对游客同样生效；须排在 notify 之后；resume/登录中途不自动弹；设置手动检查保留。
- `cold-start-splash`：补强「进主页后」版本提示场景，明确游客与串行顺序，且不依赖喂养页。

## Impact

- **壳层**：`UcgHomeShell` 首帧/挂载 bootstrap。
- **喂养页**：`HomeScreen` 去掉自动 notify/version；修正或清理登录 listen 上误挂的 dialog 路径。
- **既有 UI**：复用 `maybeShowNotifyBannerPrompt`、`maybeShowVersionPrompt`（弹窗内容与 dismiss/强阻断语义不变）。
- **HTTP**：notify 仍无鉴权独立 host；version 仍 `withAuthorization: false`；挂载 postFrame 直接调用，非 listener 风暴（若用 listen 须遵守 side-effect-http-governance）。
- **测试**：不新建 `**/test/**`；手工验收冷启预测页、游客、维护优先、登录中途/resume 不弹。
