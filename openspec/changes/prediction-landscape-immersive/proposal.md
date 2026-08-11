## Why

预测页横屏分栏已尽量放大内容，但仍保留系统状态栏占位，且设备会按系统超时熄屏，不适合作为床边常亮看板。需要在「预测页 + 横屏」时进入沉浸并保持亮屏，离开或回竖屏后恢复。

## What Changes

- 当智能预测页可见且 `Orientation.landscape`：启用沉浸式系统 UI（隐藏状态栏，采用与现有媒体全屏一致的 sticky 沉浸），并关闭 `SafeArea` 对顶/底的占用以最大化展示。
- 同期启用防熄屏（wakelock）；竖屏或离开预测页时 **必须** 关闭 wakelock 并恢复系统 UI（`edgeToEdge` 或与进页前一致）。
- 范围仅限 **预测页横屏**；喂养/广场横屏不改。
- Web 可不生效（标注 App-only）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：增加预测页横屏沉浸式系统栏与防熄屏、以及离开/竖屏恢复的要求。

## Impact

- 代码：`smart_prediction_screen.dart`（或薄封装 lifecycle）；依赖新增 `wakelock_plus`（或等价）；对照 `ucg_media_viewer` 的 SystemChrome 进出成对调用，避免互相踩踏。
- 规格：增量 `smart-prediction-page`；不改后端。
- 测试：不新建 `**/test/**`；手工横竖切换与离开预测页冒烟。
