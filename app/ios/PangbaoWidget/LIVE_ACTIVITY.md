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

## ContentState（Go → Codable）

**Imminent：** `title`、`phase`、`nextAt`  
**Timing：** `eventName`、`startTime`、`phase`

## Token

`POST /app/api/push/live-activity/register`  
`tokenKind`=`push_to_start`|`activity`，`attributesKind`=`imminent`|`timing`。

主 App `PredictLiveActivityBridge` 监听 token；**禁止** `Activity.request`。

## 深链

锁屏点击：`pangbao://live-activity/imminent` 或 `.../timing` → 投递 `bizType=predict_imminent` 进预测页；**不**客户端 dismiss。

## 特性开关

服务端 `PUSH_LIVE_ACTIVITY_ENABLED=true` 后才会扇出。
