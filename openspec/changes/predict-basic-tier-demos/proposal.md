## Why

基础版两档墙能力说明目前是纯文字 Markdown，用户难把条目和真实界面场景对应起来。不提供贴图资源的前提下，用代码绘制中档「demo 示意」小控件，能提升可读性与说服力，且几乎不增加包体积。

## What Changes

- 基础版墙正文由整段 Markdown **改为**结构化能力列表：每条含 emoji/标题/短说明 + **下方**中档代码绘制 demo（固定假数据、不可点）。
- 八条能力均配 demo：智能估算下次、推送提醒、桌面小组件、家庭共享、横向投屏、语音球、多日趋势、小智音箱。
- Pro 档仍用 catalog Markdown；不强制 Pro 配 demo。
- 不引入图片资产；不接真实 Riverpod/网络数据。

## Capabilities

### New Capabilities

- （无）行为落在既有两档墙能力上。

### Modified Capabilities

- `predict-capability-tier-wall`：基础版正文改为带场景 demo 的结构化列表（中档深度）。

## Impact

- Flutter：`predict_capability_tier_wall.dart`、可选新建 `predict_basic_tier_demos.dart`；`predict_capability_tier.dart` 文案结构从 MD 常量改为条目模型。
- 无 Go / Android 原生；Release APK N/A。
