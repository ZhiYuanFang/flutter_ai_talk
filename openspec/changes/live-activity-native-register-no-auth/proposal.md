## Why

App 未启动时系统经 Push-to-Start 已在锁屏展示 Live Activity，但 per-activity update token（`tokenKind=activity`）常无法在短唤醒窗口内经 Flutter 登录壳上报；对端依赖该 token 做 update/end，缺失会导致清场失败与推送堆积。既有 early observe + Dart Bearer register 无法作为「不打开 App 也必须上报」的硬保证；原生若再挂 accessToken/刷新则成本高、窗口内成功率仍不确定。

## What Changes

- iOS 主 App **必须**在拿到 Live Activity token（尤其 `tokenKind=activity`）后，于系统唤醒/后台窗口内由**原生直接** `POST /app/api/push/live-activity/register`，**不得**以 Flutter 引擎就绪或 Dart 登录门闸为该路径成功的前提。
- 请求体 **必须**携带非零 `wxId`（登录成功时写入原生可读存储；登出清除）；**必须**继续携带既有 `deviceKey` / `tokenKind` / `attributesKind` / `token`（`activity` 时 `activityId` 非空）。
- **BREAKING（对端契约）**：该接口 **必须不再**以 Bearer/JWT 作为成功落库的前置条件；Go 侧对该 path **必须**放行并按 body.`wxId` 落/更新对应 Live Activity token。产品接受公开写面的最坏后果（无法自动关闭锁屏 LA / 残留至系统超时），换取上报成功率。
- **不得**在原生侧复制 accessToken、做 refresh，或把 Flutter 会话管理整体迁到原生。
- **不得**再将「用户打开 App 后自动补扫/restartListening 专为补报 activity token」作为自动兜底策略或硬需求；前台/进程内自然收到的 token 仍可上报；设置页手动重试 MAY 保留作排障。
- 保留 early observe 与内存 inbox 等既有观察能力；HTTP 主路径改为原生免鉴权上报（Dart 路径 MAY 改为同契约补传，不得再把「仅已登录 Bearer」当作 activity 上报的唯一通道）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：Live Activity token 上报改为原生可免 Bearer、body 必带 `wxId`；唤醒窗口内 MUST 原生直报；取消「打开 App 自动补 activity token」硬兜底；与对端「该接口不做 token 鉴权拦截、按 wxId 落库」对齐。

## Impact

- iOS：`PredictLiveActivityBridge`（原生 HTTP register）、Keychain/`wxId` 缓存读写、API base URL 配置；`LIVE_ACTIVITY.md`。
- Flutter：登录/登出同步 `wxId` 到原生可读存储；`LiveActivityRegistrationService` 契约调整（`wxId`、不再依赖 Bearer 作为唯一门闸）；文档与诊断文案若提及「须登录才 register」须更新。
- 对端 `go_ai_talk` change `live-activity-register-no-auth-go`（twin，本仓不改 Go 代码）：网关对该 path 放行；按 `wxId` upsert LA token；字段表增加 `wxId`。
- 对照：`live-activity-token-early-observe`（作废「仅 Dart HTTP / 打开补扫硬兜底」叙事）、`predict-ios-live-activity`、`live-activity-channel-retain`；基线 `openspec/specs/v2.1.4.md`（LA 能力主要在历史 change specs 中演进）。
- 无 Android/Web Live Activity；不引入 iOS 18 channel/broadcast。
