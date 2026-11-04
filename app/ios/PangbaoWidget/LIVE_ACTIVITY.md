# iOS Live Activity（与 Go `predict-live-activity-push` 对齐）

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
| Imminent | `activityId`、`deviceNo`、`eventId`、`nextAt` |
| Timing | `activityId`、`deviceNo`、`historyId`、`eventId` |

- `eventId`：事件目录 id（十进制字符串与 Flutter catalog `def.id` 对齐）。客户端用其查 App Group 视觉索引，**推送不得下发 logo / color**。
- `nextAt` / ContentState 内时间字段：均为 **unix 秒**（非毫秒）。Timing `startTime` 若误用毫秒会导致锁屏已计时卡在 `00:00`。

## ContentState（Go → Codable）

**Imminent：** `title`、`phase`、`nextAt`（unix 秒）  
**Timing：** `eventName`、`startTime`（unix 秒）、`phase`

不含 `logo` / `color` / `logoFile`。

## 客户端视觉（App Group）

- Group：`group.com.fzy.pangbao.widget`
- 索引键：`laEventVisuals` → JSON `{ "<eventId>": { "color": "#RRGGBB", "logoFile": "home_widget_logos/…" } }`
- Logo 文件：`home_widget_logos/{eventId}.{ext}`（Flutter `widgetLogoFileForEvent` 预热）
- Extension 按 Attributes.`eventId` 查找；缺失则 BrandLogo / 色球兜底；深色底上事件色过深则提亮

## Token

`POST /app/api/push/live-activity/register`  
`tokenKind`=`push_to_start`|`activity`，`attributesKind`=`imminent`|`timing`。

主 App `PredictLiveActivityBridge` 监听 token；**禁止** `Activity.request`。

## 深链

锁屏点击：`pangbao://live-activity/imminent` 或 `.../timing` → 投递 `bizType=predict_imminent` 进预测页；**不**客户端 dismiss。

## 特性开关

服务端 `PUSH_LIVE_ACTIVITY_ENABLED=true` 后才会扇出。

## 对端联调（本仓不实现 Go fanout）

- Timing 起活动 **必须** 带固定字段 `eventId`
- `startTime` / `nextAt` **必须** 为 unix **秒**
