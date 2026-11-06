# iOS Live Activity（与 Go `predict-live-activity-push` / `live-activity-expect-lock-go` 对齐）

## Attributes 名

| attributesKind | Swift / APNs attributes-type |
|----------------|------------------------------|
| `imminent` | `PredictImminentAttributes` |
| `timing` | `PredictTimingAttributes` |

可用 env `PUSH_LA_ATTR_IMMINENT` / `PUSH_LA_ATTR_TIMING` 覆盖服务端侧字符串，须与本 Extension 类型名一致。

## activityId

| 类型 | 服务端格式 |
|------|------------|
| Imminent | `imminent:{wxId}` |
| Timing | `timing:{deviceNo}:{historyId}` |

## 固定 Attributes（Push-to-Start / start）

| 类型 | 字段 |
|------|------|
| Imminent | `activityId`、`deviceNo`、`eventId`、`nextAt`、`title` |
| Timing | `activityId`、`deviceNo`、`historyId`、`eventId`、`eventName`、`startTime` |

- `eventId`：事件目录 id（十进制字符串与 Flutter catalog `def.id` 对齐）。客户端用其查 App Group 视觉索引，**推送不得下发 logo / color**。
- `nextAt` / ContentState 内时间字段：均为 **unix 秒**（非毫秒）。Timing `startTime` 若误用毫秒会导致锁屏已计时卡在 `00:00`。
- Imminent `title`：Go twin 已发基句（如 `{昵称}要{事件名}了`），**不含**「，预计这次约…」后缀。

## ContentState（Go → Codable）

**Imminent：** `title`、`phase`、`nextAt`（unix 秒）；可选 `expectKind`（`duration`|`amount`）、`expectDurationSec`、`expectAmount`（浮点）、`expectUnit`  
**Timing：** `eventName`、`startTime`（unix 秒）、`phase`；可选 `expectEndAt`（unix 秒）

不含 `logo` / `color` / `logoFile` / 成品中文 expect label / `expectLeafTitle`。缺键客户端兜底不画。

Go twin：`live-activity-expect-lock-go`（已完成）：开火透传 expect*；active-eta / history update 灌入或保留 `expectEndAt`。

## 客户端视觉（App Group）

- Group：`group.com.fzy.pangbao.widget`
- 索引键：`laEventVisuals` → JSON `{ "<eventId>": { "color": "#RRGGBB", "logoFile": "home_widget_logos/…" } }`
- Logo 文件：`home_widget_logos/{eventId}.{ext}`（Flutter `widgetLogoFileForEvent` 预热）
- Extension 按 Attributes.`eventId` 查找；缺失则 BrandLogo / 色球兜底；深色底上事件色过深则提亮

## 锁屏 / 灵动岛展示（客户端 UI）

- **锁屏 content（双层）**：上层窄行仅「胖宝」文字（事件提亮色，**无**圆形 App logo）；下层事件 logo（约 37pt）+ 标题列（主标题；Timing 可有副行）+ 右侧槽。
- **Timing**：主标题仅为事件名（**不**拼「计时中」）；有正 `expectEndAt` 时副行「预计 HH:mm 结束」（无「约」、无超时后缀）；右侧系统 `timerInterval` 已计时（可带秒，约 99h 上界），字号为 trailing `.title` 基准。
- **Imminent**：主标题展示推送基句；右侧有可用 expect 时短版「预计{h}时{m}分钟」/「预计{m}分钟」/「预计{N}{unit}」；**右槽字号 = `.title` 基准 − 5pt**；无 expect 空右槽。MUST NOT 展示基于 `nextAt` 的「预计m分钟后」、倒计时、「已过时」。
- **Dynamic Island**：Timing compact / expanded 时间位为零填充 **`hh:mm:ss`**，compact 右槽短占位箍宽。Imminent Island **不**展示时间维 / expect；compact **不**预留右侧 timer 槽。compactLeading 展示 **完整** 事件名（仅 trim）；expanded 中心标题产品侧不硬截。

## Token

`POST /app/api/push/live-activity/register`  
Body：**非零 `wxId`**、`deviceKey`、`tokenKind`=`push_to_start`|`activity`、`attributesKind`=`imminent`|`timing`、`token`；`activity` 时 `activityId` 非空。

- **对端**：`go_ai_talk` change `live-activity-register-no-auth-go` — gateway **不做 Bearer 拦截**；按 body.`wxId` 落 `push_live_activity_token`。
- **客户端主路径**：Push-to-Start 唤醒窗内 **原生 URLSession** 直报（不附 Authorization）；登录后把 `wxId` / `deviceKey` / `apiBaseUrl` 写入 App Group + Keychain（`LiveActivityNativeRegister`）。
- **Dart**：可选补传（同契约 body + 可附带 Bearer，服务端忽略）；**不**把「打开 App 自动 restartListening 补 activity」当作硬兜底；设置页手动重试仅排障。

主 App `PredictLiveActivityBridge`：

- **Early observe**：`didFinishLaunching` 即订 Push-to-Start / per-activity（不依赖 Dart `startListening`）。
- **补扫**：`beginObserving` 枚举 `Activity.activities` 再订 `activityUpdates`。
- **原生 register**：`deliver` 时先 `LiveActivityNativeRegister.registerIfPossible`（有缓存 wxId 即 POST）。
- **Inbox**：channel / Dart 未可收时进程内暂存；`startListening` → flush 供 Dart 补传。登出 `pauseDartListening` + `clearRegisterContext`。
- **禁止** `Activity.request`。

### 联调检查清单（Flutter ↔ Go twin）

1. Go 已合：精确豁免 `POST /app/api/push/live-activity/register`；body 必含 `wxId`。
2. App 已登录一次（写入原生上下文）→ kill → Push-to-Start 出锁屏 → **不打开 App** → 服务端应有该 `wxId` 的 `tokenKind=activity`。
3. 登出后清上下文 → 再唤醒不得按旧 `wxId` 落库。
4. 前台 token 轮转 / 设置页手动重试仍可用。

真机核对：killed → Push-to-Start → **不打开** 亦应 `nativeRegister ok`（或对端表有 activity 行）；前台起 LA 路径回归不破。

## 深链

锁屏点击：`pangbao://live-activity/imminent` 或 `.../timing` → 投递 `bizType=predict_imminent` 进预测页；**不**客户端 dismiss。

## 特性开关

服务端 `PUSH_LIVE_ACTIVITY_ENABLED=true` 后才会扇出。

## 对端联调

- Timing 起活动 **必须** 带固定字段 `eventId`、`eventName`、`startTime`；ETA 经 active-eta update 带 `expectEndAt`
- Imminent start **必须** 带基句 `title`；有预计时另带结构化 expect*
- 锁屏标题：ContentState 为空时回退 Attributes（Timing 空名短兜底「事件」；Imminent 空名「事件即将发生」）
- `startTime` / `nextAt` / `expectEndAt` **必须** 为 unix **秒**
