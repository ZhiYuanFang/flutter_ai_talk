## 1. iOS Live Activity Extension

- [x] 1.1 新增 Imminent / Timing 两类 ActivityAttributes（`attributesKind`=`imminent`|`timing`）与锁屏 UI（logo、文案、箭头；Timing 含时间）
- [x] 1.2 开通 Live Activities / Push to Start：Extension、`NSSupportsLiveActivities` 等 Runner/Info 配置
- [x] 1.3 本机禁止对两类 LA 使用本地 `Activity.request` 承担起推送展示职责

## 2. Token 与深链

- [x] 2.1 `POST /app/api/push/live-activity/register`：分别为 imminent/timing 上报 `push_to_start`；Activity 建立后上报 `activity`+`activityId`；MUST NOT 走 `/app/api/push/register`
- [x] 2.2 点击深链进 `/home` 预测页族；点击路径不得客户端 dismiss Imminent
- [x] 2.3 若新增 Debug 日志 tag：三联改 `app_debug_log.dart`、`logcat_api_http.ps1`、`app/README.md`

## 3. 联调

- [x] 3.1 对照对端 fanout 载荷与 activity id；开关与发版顺序与 `predict-live-activity-push` 对齐
- [x] 3.2 对照本仓规格：两类 UI、仅等推送、点开不 dismiss、多 Timing、Android 无锁屏 LA
