## Why

主页「趋势」入口当前浮在底部 220px 输入区 Stack 内（`Positioned` 于语音球右上方），与字幕、按住说话控件争抢空间且不符合用户对「右上角」的预期。应将趋势入口移至 **AppBar 右侧操作区**，与历史 WS、设置并列，底部主输入区仅保留语音/文字切换。

## What Changes

- 从 `home_screen` 底部 `Stack` 移除「趋势」`FilledButton.tonalIcon`。
- 在 `AppBar.actions` 增加趋势入口（`IconButton` + tooltip「趋势」），顺序为：**历史连接** → **趋势** → **设置**（设置仍最右）。
- 点击仍导航 `/trends`；不改变趋势页与数据逻辑。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-input-history-sse`：更新「从主页进入二级功能」中趋势入口位置描述（由主输入区右上方改为 AppBar 右侧）。

## Impact

- `app/lib/ui/home_screen.dart`
