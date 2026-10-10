## Why

预约「下一次」专用 sheet 基线要求年月日时分，但实现用 `CupertinoDatePicker.dateAndTime`，缺少可发现的年份列，跨年预约难用。新增预约记录后若已有未来 `nextAt` 则不引导重约，不符合「本次发生后应重新约定下次」的产品语义。预测卡已有 countdown 时缺少改约入口（「补充下次」仅在无 pred 时出现）；竖屏与横屏均需一致可点改约。

## What Changes

- 专用下一次预约 sheet：标题下可点年份行 + **月/日/时/分四列**滚轮（年经独立 glass 单列选择），替代 `dateAndTime` 合列。
- **仅正常新增**（`EventRecordIntent.add`）预约根记录成功后：先 `PUT nextAt=0`；成功再弹专用 sheet；**清空失败则不弹**（toast）。补充上一次仍仅空/过期才弹，不清空。
- 预约热态卡在有可展示 countdown 时：点倒计时块（文案+数字，含逾期）打开专用 sheet 修改下次约定，**不得**走加喂养；整卡其余区域仍可新增。
- **横屏与竖屏一致**：预约卡有 pred 时横屏亦须展示可点 countdown 块（不得仅有图无线索）。

## Capabilities

### New Capabilities

- （无）行为落在既有 `appointment-event-client` / `smart-prediction-page`。

### Modified Capabilities

- `appointment-event-client`：sheet 可点年份 + 四列月日时分；新增后清 nextAt 再引导；清空失败不弹。
- `smart-prediction-page`：预约卡 countdown 可点改约；横竖屏同源。

## Impact

- `appointment_next_sheet.dart`：自定义滚轮；`maybePrompt…` / 新增路径清零逻辑。
- `event_add_actions.dart`（或等价）：区分 add vs supplement。
- `smart_prediction_screen.dart`：预约卡 countdown 手势；横屏布局补 countdown。
- 无 Go API 变更；仍用既有 `GET/PUT /device/app/api/appointment/next`。
