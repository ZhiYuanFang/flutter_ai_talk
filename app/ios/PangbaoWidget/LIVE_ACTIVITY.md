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
| Imminent | `activityId`、`deviceNo`、`eventId`、`nextAt`、`title` |
| Timing | `activityId`、`deviceNo`、`historyId`、`eventId`、`eventName`、`startTime` |

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

## 锁屏 / 灵动岛展示（客户端 UI）

- **锁屏 content（双层）**：上层窄行圆形 BrandLogo +「胖宝」（事件提亮色）；下层事件 logo + 既有标题（Timing「…计时中」）+ 右侧中文到分钟时间。
- **锁屏时间**：Timing「已过去h时m分钟」（`h=0` 省略时 →「已过去m分钟」）；Imminent「预计m分钟后」（总分钟）；不足 1 分钟按 1；Imminent 过期 **不** 展示「已过时」或其它时间维文案。
- **Dynamic Island 时间位**：compact / expanded 均为零填充 **`hh:mm:ss`**（不足 1h 仍含时）；compact 继续短占位箍宽，**不用**锁屏中文长句。Imminent 过期 Island 时间位同样无时间维文案。

## Token

`POST /app/api/push/live-activity/register`  
`tokenKind`=`push_to_start`|`activity`，`attributesKind`=`imminent`|`timing`。

主 App `PredictLiveActivityBridge` 监听 token；**禁止** `Activity.request`。

## 深链

锁屏点击：`pangbao://live-activity/imminent` 或 `.../timing` → 投递 `bizType=predict_imminent` 进预测页；**不**客户端 dismiss。

## 特性开关

服务端 `PUSH_LIVE_ACTIVITY_ENABLED=true` 后才会扇出。

## 对端联调（本仓不实现 Go fanout）

- Timing 起活动 **必须** 带固定字段 `eventId`、`eventName`、`startTime`
- Imminent start **必须** 带 `title`（与 ContentState 同一句）
- 锁屏标题：ContentState 为空时回退 Attributes，避免「事件计时中 / 事件即将发生」
- `startTime` / `nextAt` **必须** 为 unix **秒**
