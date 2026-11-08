# iOS Live Activity（与 Go `unify-live-activity-list` 对齐）

## Attributes 名

| 说明 | Swift / APNs attributes-type |
|------|------------------------------|
| 统一单条 | `BabyLiveActivityAttributes` |

可用 env `PUSH_LA_ATTR_TYPE` 覆盖服务端侧字符串，须与本 Extension 类型名一致。

旧双轨 `PredictImminentAttributes` / `PredictTimingAttributes` **已废弃**。

## activityId

统一 start Attributes：`activityId` = `baby:{wxId}`（Go 组装）；另含 `deviceNo`。

## ContentState（Go → Codable）

```json
{
  "phase": "active" | "cleared",
  "items": [ /* 见下 */ ],
  "ack": "可选；仅 APNs event=update 注入的临时回执序号"
}
```

- **`ack`**：与 `phase` / `items` **同包**下发（Go `live-activity-update-ack-timeout`）；`start` / `end` 通常无此字段。锁屏/Island **忽略**；主 App Runner 非空则立即原生回执（见下「Update ack」）。缺键解码为空串。

### items[] 排序（Go Refresh）

1. 预测段 `kind=imminent`：pending 全量，`nextAt` **升序**
2. 进行中段 `kind=timing`：`end_time=0`，`startTime` **倒序**

### item 字段

| kind | 字段 |
|------|------|
| `imminent` | `eventId`、`nextAt`（unix 秒）、`title?`、`expectKind?` / `expectDurationSec?` / `expectAmount?` / `expectUnit?` |
| `timing` | `historyId`、`eventId`、`eventName?`、`startTime?`（unix 秒）、`expectEndAt?`（unix 秒） |

不含 `logo` / `color` / 远程图 URL。缺键客户端兜底不画。

时间字段均为 **unix 秒**（非毫秒）。

## 客户端视觉（App Group）

- Group：`group.com.fzy.pangbao.widget`
- 索引键：`laEventVisuals` → JSON `{ "<eventId>": { "color": "#RRGGBB", "logoFile": "…" } }`
- Extension 按 item.`eventId` 查找；缺失则品牌/色球兜底

## 锁屏 / 灵动岛

- **锁屏**：内容区 **不**画 App 名「胖宝」顶栏；按 `items` **动态纵向**堆叠：
  - imminent 行：logo + title + 可选 expect 短版右槽（`.title−5pt`）；**不**画 nextAt 倒计时
  - timing 行：logo + 事件名 + 可选「预计 HH:mm 结束」+ 右侧系统已计时
- **Dynamic Island**：仅 `items.first`；按该条 kind 沿用既有 Island 样式（imminent 无时间右槽；timing 带已计时）

## Token

`POST /app/api/push/live-activity/register`  
Body：**非零 `wxId`**、`deviceKey`、`tokenKind`=`push_to_start`|`activity`、`token`。  
**不再传** `attributesKind` / `activityId`。

- 对端：gateway 免 Bearer；按 body.`wxId` 落库；唯一键 `(wx_id, device_key, token_kind)`。
- 客户端主路径：Push-to-Start 唤醒窗内 **原生 URLSession** 直报。
- Dart：可选补传（同契约）。

主 App Bridge：仅观察 `BabyLiveActivityAttributes`；early observe + inbox flush 不变。**禁止** `Activity.request`。

## Update ack

`POST /app/api/push/live-activity/ack`  
Body：**非零 `wxId`**、`deviceKey`、`ack`（与最近一次 update ContentState.`ack` 一致，≤64）。

- 对端：gateway 免 Bearer（对齐 register）；仅 `ack == last_sent_ack` 时写 `last_acked_ack`；超时未 ack 则删 activity 并用同机 `push_to_start` restart（`LIVE_ACTIVITY_ACK_TIMEOUT_MS`，默认 3000）。
- 客户端主路径：ActivityKit `content.state` / `contentUpdates` 见到非空 `ack` 后，**原生 URLSession** 直报（复用 register 缓存的 wxId/deviceKey/apiBase）。
- **不得** Dart / MethodChannel 补传；**不得**在 Widget Extension 内发 ack。

## 深链

`pangbao://live-activity`（及旧 `/imminent` `/timing` 兼容）→ `bizType=predict_imminent` 进预测页；**不**客户端 dismiss。

## 特性开关

服务端 `PUSH_LIVE_ACTIVITY_ENABLED=true` 后才会扇出。空 `items` → end 摘屏。
