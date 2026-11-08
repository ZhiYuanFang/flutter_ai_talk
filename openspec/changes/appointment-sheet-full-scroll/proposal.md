## Why

预约「下一次」sheet 为让四列滚轮 `Expanded` 填高，关掉了外壳滚动（`scrollable: false`）。横屏再叠加键盘 inset 时可用高度可压到数十像素，收起滚轮后的标题/年份/备注/确认仍溢出。需要整窗可滚，矮约束下能滚到备注与确认。

## What Changes

- `showAppointmentNextSheet`：改为整窗可滚（`scrollable: true` / 与 `AppAdaptiveBottomSheet` 默认一致）。
- body：在滚动视口内用**固定高度**四列滚轮（不再依赖有界高 `Expanded`）；保留备注获焦/键盘可见时收起滚轮与 `respectKeyboardInset` + `keyboardLift`。
- 横屏与竖屏同一套可滚策略（不单独「仅横屏可滚」）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `appointment-event-client`：专用下次预约 sheet MUST 整窗可滚；矮屏/键盘下 MUST 能滚到备注与确认且不 RenderFlex overflow。

## Impact

- UI：`appointment_next_sheet.dart`（`scrollable`、body 布局分支）。
- 无 Go/API 变更；与 `appointment-keyboard-unbounded-last` 的键盘收轮并存。
