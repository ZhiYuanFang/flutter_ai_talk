## Why

桌面小组件已落地，但预测主路径缺少可发现入口，用户不易理解「可在桌面看预测」。需要在预测页竖屏用悬浮入口秀出能力，并按是否已钉小组件分流引导。未登录 / 未绑定宝宝时无可用 device 数据，且 Auth 冷态已有滑动引导，底栏 FAB 会抢注意力，故这两态不展示入口。

## What Changes

- 预测页**仅竖屏**底部固定悬浮按钮；Web / 非移动 / 横屏 **不得**展示。
- **未登录或已登录未绑定**（无可用 deviceNo）时 **不得**展示该悬浮入口；列表底留白一并收窄。
- 文案随 `HomeWidget.getInstalledWidgets()`：未钉 →「添加桌面小组件」；已钉 →「查看桌面小组件」（查询失败按未钉）。
- 新页（路由如 `/widgets/showcase`）：下方 **仅 large** 的 Flutter 对标预览（假玻璃大图神似，非像素级 XML 复制）。
- **未钉**：展示如何添加的设置说明；**不得**展示「刷新小组件数据」。
- **已钉**：展示能力说明（替代设置教程）；**必须**提供「刷新小组件数据」（复用既有 `ensureWidgetReadyFromRef` / sync）。
- 不改 native 三尺寸布局；设置页旧 `HomeWidgetSettingsSection` 可保持注释或链到新页（非必须）。

## Capabilities

### New Capabilities

- `prediction-widget-showcase`：预测竖屏入口（须已绑定）、安装态分流、large Flutter 预览、刷新闸门与文案。

### Modified Capabilities

- （无）原生小组件契约仍由基线 `home-feed-upcoming-widget` 等覆盖；本变更不改 payload / native 渲染要求。

## Impact

- UI：`smart_prediction_screen.dart` 竖屏 Stack FAB（`bound && !landscape && platform`）；新 screen + go_router 路由。
- 数据：`HomeWidget.getInstalledWidgets()`；预览复用 `buildWidgetRows` / visual payload / sync。
- 进页 / App resume 刷新安装态。
- 无后端；原则上不改 `app/android/**`；不新建 `**/test/**`。
- 对照基线 `openspec/specs/v2.1.0.md`（`home-feed-upcoming-widget`）。
