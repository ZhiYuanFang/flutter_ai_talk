## Why

智能预测「网格」目前为等高双列，事件图挤在标题行、主视觉弱；需要瀑布流错落布局，并把事件图放大放到倒计时上方，同时用心跳动画突出「最先要发生」的事件。

## What Changes

- 紧凑布局（原 grid）改为 **双列瀑布流**（卡片高度随内容，非固定 aspectRatio）；列表布局与切换、**默认紧凑 + 本地记忆**保持（已有 store，键可仍用 `grid` 表示瀑布流，免迁移）。
- 瀑布流卡片：标题行仅 **事件名 + 推演开关**（无小 logo）；**较大 EventLogo 居中**置于倒计时上方；倒计时规则不变（含超时停表文案）。
- **心跳**：在推演开启且可预测、**未超时**的事件中，取 `nextAt` 最早者；其大图持续心跳缩放动画；其余静止。若无未超时可预测事件则无心跳。
- 列表态折线卡不受上述卡片结构约束（仍可标题行带 logo）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：紧凑态瀑布流；卡片图/倒计时结构；最近未超时事件心跳。

## Impact

- UI：`smart_prediction_screen.dart`（GridView → 瀑布流；compact 卡片重组；心跳 Stateful 包装）。
- 布局偏好：沿用 `prediction_layout_store` / provider；默认网格已满足，本 change 不强制清用户已存 `list`。
- 优先无新依赖（双列自铺）；若引入 masonry 包须写入 pubspec 并说明。
- 不改预测算法、range、服务端；不自动新建测试文件。
