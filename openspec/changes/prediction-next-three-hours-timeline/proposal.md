## Why

智能预测页在「值得留意」之下缺少未来几小时的事件节奏一览；家长需要一眼看到「接下来 3 小时」谁先谁后，并能快速回到喂养主页记录。

## What Changes

- 当存在窗内预测段落时，在留意卡片区下方展示 **「接下来3小时」** 时间线（不要求留意非空）。

- 数据：推演开启且可预测的事件中，`nextAt ≤ now + 3h` 的全部条目（**含已超时**），按 `nextAt` 升序；文案形如 `HH:mm 左右{事件名}`，条目间用 ` → ` 连接。
- 过长：**折行**；默认收起（限制可视行数），**点击**在展开/收起间切换。
- **点击**时间线（含展开态）**必须**跳转喂养主页（`HomePagerPage.feeding` 或等价），不得打开陪伴聊天。
- 推演关闭事件不进入时间线；无符合窗条件的事件时，有留意也不展示该时间线块（或仅标题空态——实现取「无条目则整块隐藏」）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：留意下方三小时时间线的展示、展开与跳转喂养页。
- `prediction-care-alert`：时间线与留意同屏顺序（留意在上、时间线在下；无留意则无时间线）。

## Impact

- UI：`smart_prediction_screen.dart`（留意与卡片区之间）；可抽小组件/纯函数拼文案。
- 数据：复用 `smartPredictionRowsProvider` / 预测结果，无新 HTTP。
- 导航：`homePagerRequestProvider.requestPage(HomePagerPage.feeding)`。
- 不改服务端、不自动新建测试文件。
