## Why

基础版能力墙上「小智音箱」品牌名对宝妈难懂；且中档 demo 仅示意、不可进真实能力，墙变成说明书而非入口。需要弱化品牌、说清利益，并让每条能力可点进对应页面或页内动作。

## What Changes

- 音箱条目标题改为 **「家中音箱 · 免动手」**；副标题强调连接实体硬件、脱离手机、纯语音记录与查询宝宝日常；demo 角标 **「可付费开通」保持不变**。
- 基础版能力 **整行可点**（demo 区仍可 IgnorePointer，点击落在行上）：先关墙，再按条目执行落地动作。
- 落地表：
  - 智能估算下次 → 仅关墙
  - 智能推送提醒 → `/settings/notifications`
  - 桌面小组件 → `/widgets/showcase`
  - 家庭全员共享 → **不跳转**（可仅关墙）
  - 横向投屏共享 → 关墙后走预测页现有「进入投屏模式」确认 → 锁横屏
  - 语音球唤醒 → 关墙后将预测语音球从 peek **拉成贴边 engaged 全圆**（可点，不浮空）
  - 多日趋势图 → `/trends`
  - 家中音箱 → `/settings/xiaozhi-speaker`
- 为投屏确认与语音球 engage 增加可从墙触发的 request 桥（不叠在墙路由上）。
- **修正** `predict-basic-tier-demos` 中「整条不可点/不导航」的约束：改为 **行可点、demo 本身不单独驱动业务**。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-capability-tier-wall`：基础版音箱文案弱化品牌；行级点击关墙并导航/触发投屏确认/语音球贴边 engage。

## Impact

- Flutter：`predict_capability_tier.dart` 文案；`predict_basic_tier_demos.dart` / 墙行 `onTap`；`EdgeDockController` 补 engage；语音球 / 投屏 request provider；`ucg_home_shell` / `smart_prediction_screen` / `prediction_voice_edge_dock` 消费请求。
- 无 Go / Android 原生；Release APK **N/A**。
