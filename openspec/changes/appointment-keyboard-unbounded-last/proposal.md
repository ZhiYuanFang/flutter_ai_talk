## Why

预约「下一次」sheet 备注获焦后键盘会盖住输入框；同时瀑布预约卡「上一次」仍依赖近 7 日窗 / tip 缓存，久未记录时缺时间或缺 history remark。Go 已提供 `filter` + `ignoreTimeRange`，客户端尚未接线。

## What Changes

- 预约下次 sheet：备注获焦 / 键盘升起时收起四列时间滚轮，并用与新增事件同族的键盘避让（`respectKeyboardInset` + `keyboardLift`）；失焦 / 键盘收起后恢复滚轮。
- 预约卡「上一次」：经 `GET /device/history/api/filter`（`eventIds`=根及子、`limit=1`、`ignoreTimeRange=true`）取最近一条 History，展示时间与非空 ` · remark`；**不得**再仅依赖近 7 日 range 窗；**不得**新造 Go latest 接口；**不得**使用整机 `event/latest`。
- Flutter `tryLoadHistoryFilter`（及调用链）补传 `ignoreTimeRange`。
- 范围仅预约根 / 预约 sheet；非预约预测卡 lastAt 路径不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `appointment-event-client`：预约卡上次发生改走不限窗 `filter`（含 `ignoreTimeRange`）；预约 sheet 键盘避让与滚轮收起。

## Impact

- 主要：`appointment_next_sheet.dart`、`smart_prediction_screen` / 预约 last 拉取、`feed_repository` / `remote_feed_repository` filter 查询参数。
- 对端：复用已合入的 Go `ignoreTimeRange`；无新 Go 变更、无 **BREAKING** HTTP。
- 关联：`smart-prediction-appointment-accuracy-ux` 已落地预约备注读写与竖列表过滤；本变更补键盘与不限窗上次。
