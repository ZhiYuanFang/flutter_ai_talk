## Why

主页喂养历史列表将**最新记录锚在底部**，用户常态停留在底部查看。现有 `RefreshIndicator` 仅在**列表顶部**下拉生效：触顶时优先加载更旧页，刷新最新需先滚到顶部，与「在最新位置主动对齐服务端」的预期不符。需要在底部提供**带上拉阈值**的手势，触发已有的 `refreshFromRemote`（page=1）更新最新喂养信息。

## What Changes

- 在 `HomeHistoryScroll` 增加底部上拉检测：用户处于列表底部附近时，继续上拉超过最小阈值并在松手时触发 `refreshFromRemote`。
- 底部上拉**仅**刷新最新一页（page=1），**不得**触发加载更旧页（`loadMoreHistory`）。
- 提供底部轻量视觉反馈（上拉进度 / 刷新中），刷新完成后锚回最新记录。
- **保留**顶部 `RefreshIndicator` 与既有「触顶 loadMore / 非触顶 refresh」分流，不改动 HTTP/WS 协议。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-history-pagination`：补充「底部上拉刷新最新一页」需求与场景；与既有「顶部下拉刷新最新一页」并列。

## Impact

- **代码**：`app/lib/ui/home_history_scroll.dart`（手势检测、底指示 UI）；`home_screen.dart` 接线不变（仍用 `onRefresh` → `refreshFromRemote`）。
- **数据**：复用 `HomeHistoryNotifier.refreshFromRemote` 与 `GET /device/history/api/list?page=1`；刷新后 `highestPageLoaded` 重置为 1（与基线一致）。
- **依赖**：无新包；可能微调 `ScrollPhysics` 以改善 Android 底端 overscroll 手感（实现细节见 design.md）。
