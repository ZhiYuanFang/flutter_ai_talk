## Why

居中小贴士拖动时，横向手势常被下层 PageView 抢走，顶标拖拽手感差；同时需要**点顶标原地折叠成圆**（与四边贴边吸入并存），让用户快速收起卡片而不 dismiss。

## What Changes

- 小贴士**可拖区域**明确包含顶部胖宝圆标与正文卡（同一拖动手势）；关闭/对话按钮不参与拖动。
- 指针落在 tip **有界命中盒**内时，**必须**拦截并禁止透传为 PageView 横滑（pointer down 即锁滑，抬起/取消解锁）；空白区仍可点历史。
- **输入模式悬浮球**（贴边半圆/全圆/自由悬浮）命中热区内同样：**pointer down 即锁 PageView**，与 tip 球一致（点按切换模式仍可用）。
- **点击顶标**（短按、非拖）：播放缩小动画，将卡片收到图标下方/并入圆，进入 **collapsed**（原地浮圆）；再点圆展开。与四边 **docked**（过半贴边吸入）区分。
- 关闭仍 dismiss；新 tip（presentationGeneration）仍强制居中 expanded。

## Capabilities

### New Capabilities

- `home-tip-gesture-chrome`：顶标可拖、命中区锁 PageView、点标折叠/展开动画与 collapsed 态。

### Modified Capabilities

- `home-tip-edge-dock`：补充与 collapsed 的边界（点标 ≠ 贴边吸入）；拖动手势含顶标。

## Impact

- 代码：`home_tip_panel.dart`（手势/状态机）、`onDraggingChanged` 提前到 pointer down；可能微调 `ucg_home_shell` 禁滑（复用既有回调即可）。
- 依赖：`home-tip-center-card` / `home-tip-edge-minimize` 已落地的居中卡与四边 dock。
- 无 Android 原生。
