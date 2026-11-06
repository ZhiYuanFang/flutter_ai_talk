## 1. 契约与文档

- [x] 1.1 更新 `app/ios/PangbaoWidget/LIVE_ACTIVITY.md`：原生免 Bearer register、body 必含 `wxId`、对端不做 token 鉴权、取消打开 App 自动补 activity 硬兜底；注明 twin Go 联调项
- [x] 1.2 与 `go_ai_talk` change `live-activity-register-no-auth-go` 对齐字段表（`wxId` + 既有字段）与网关放行；本仓不改 Go，联调检查清单写入 README 或 LIVE_ACTIVITY.md

## 2. wxId 缓存（Dart ↔ 原生）

- [x] 2.1 Dart：登录成功 / 会话刷新得到非零 `wxId` 时写入原生可读存储（Keychain；accessibility 兼顾后台唤醒）
- [x] 2.2 Dart：登出 / 硬失效时清除缓存 `wxId`
- [x] 2.3 原生：提供读缓存 `wxId` API；无非零值时跳过 register 并 `NSLog`/`AppDebugLog` 可对齐的诊断（勿打 token）

## 3. 原生免鉴权 register

- [x] 3.1 `PredictLiveActivityBridge`（或并列模块）：拿到 Push-to-Start / activity token 且有 `wxId` 时，用 URLSession `POST /app/api/push/live-activity/register`（body：`wxId`、`deviceKey`、`tokenKind`、`attributesKind`、`token`，activity 时 `activityId`）；不附 Bearer
- [x] 3.2 原生可读 API base URL / `deviceKey`（与 Dart 安装级 `deviceKey` 一致来源）；失败不崩溃，记录诊断日志
- [x] 3.3 原生成功身份去重（`wxId|deviceKey|kind|attr|activityId|token`），避免与重复 `pushTokenUpdates` / Dart 补传刷屏
- [x] 3.4 确认唤醒路径 **不** 等待 Dart `startListening` / 登录壳

## 4. Dart 管线调整

- [x] 4.1 `LiveActivityRegistrationService._register`：body 增加非零 `wxId`；成功不再以 Bearer 为唯一门闸（与免鉴权契约一致；可继续走 `ApiClient` 若附带 Bearer 亦可，服务端忽略）
- [x] 4.2 去掉或改写「仅已登录才 register activity」中与唤醒主路径冲突的文案/门闸；**不**新增 resume 自动 `restartListening` 专为补 activity
- [x] 4.3 设置页手动重试若保留：仅排障，不作为自动打开兜底文档化

## 5. 验证

- [ ] 5.1 真机：已登录写过 `wxId` → App killed → Push-to-Start 出锁屏 → **不打开 App** → 对端应有该 `wxId` 的 `tokenKind=activity`（依赖 twin 已放行）
- [ ] 5.2 真机：登出清 `wxId` 后唤醒收到 token → 不得再按旧 `wxId` 成功落库
- [ ] 5.3 前台起 LA / token 轮转路径回归：register 仍可用且不崩溃
