## Why

广场资格开通后，用户常停在预测页，只靠左滑才知道能进广场；有未读时也缺少预测侧的可见钩子。需要在预测竖屏提供可拖贴边的「广场球」，用与消息 tab 同源的红点引导进入广场。

## What Changes

- 新增预测竖屏 **UCG 广场 EdgeDock 贴边球**（可拖、peek / engage / float）；球面纯图形、无文字。
- 仅当 `ucgEligibility.isQualified` 为真时显示；横屏、喂养页、非预测页不显示。
- 点按球 → `homePagerRequestProvider.requestPage(ucg)`。
- 未读红点：与消息 tab 同一套 `ucgUnreadCount > 0`，只提示有未读、不显示数字；红点在球**内**角落，随贴边左右（及上下）换角，保证 peek 半圆仍可见。
- 默认右侧、纵向居中 peek；单独 prefs 记住上次拖放（edge/along 或 floating）。
- 在预测进入 / 主壳路径主动 `ucgEligibilityStateProvider.ensureLoaded()`，使球可在未先滑入 UCG 时出现。
- 与 `prediction-history-refresh-on-resume` 解耦：本变更不改 resume HTTP bundle；可依赖其已上移的 unread 同步。

## Capabilities

### New Capabilities

- `ucg-square-edge-dock`: 预测竖屏广场贴边球的可见性、交互、红点几何、位置持久化与跳转。

### Modified Capabilities

- `ucg-entry-gate`: 允许在预测页 / 主壳进入预测时主动 `ensureLoaded` eligibility（不再仅限滑入 UCG 才刷新），以便合格后球可出现；锁层与 fail-closed 语义不变。

## Impact

- UI：`smart_prediction_screen`（竖屏 Stack 挂球）、新建 `UcgSquareEdgeDock`（或等价）+ dock store。
- 状态：`ucgEligibilityStateProvider`、`ucgUnreadCountProvider`、`homePagerRequestProvider`、`EdgeDockShell` / occupancy。
- Shell：`UcgHomeShell._onEnterPredictionPage`（或等价）补 eligibility ensure。
- 无新后端 API；不新建 `**/test/**`。
