## Why

网格计时中 chrome 已落地，但仍用预测根事件的图/名/色，与真实进行中的叶子事件不一致；停止按钮也缺少持续心跳反馈。需在计时态对齐叶子身份，并为停止控件加心跳动画。

## What Changes

- 网格计时中：标题旁事件图、标题文案、elapsed/停止等强调色 **必须** 取自进行中历史对应的**叶子事件**（`lookupEventForRecord` 或等价），不得继续仅用预测行根事件。
- 叶子不可解析时：回退根事件图/名/色（或记录上的 `eventName`），不得空白崩溃。
- 底部「停止」在可点时 **必须** 持续心跳缩放动画（复用或对齐现有 `_HeartbeatLogo` 节奏）；停止请求进行中（「…」）时 **必须** 暂停心跳动画。
- 不改列表态；不改非计时网格倒计时主区。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `smart-prediction-page`：收紧计时中 chrome 的叶子身份（图/名/色）与停止按钮心跳动画要求。

## Impact

- UI：`smart_prediction_screen.dart` 计时中分支；可抽 `_HeartbeatStopButton`。
- 依赖既有 `lookupEventForRecord` / `resolveEventColor`（或叶子 `colorHex`）；承接 `prediction-grid-active-timing`。
- 无原生/新包。
