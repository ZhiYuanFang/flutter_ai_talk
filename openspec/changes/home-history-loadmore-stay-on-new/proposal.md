## Why

触顶 loadMore 后用户会先看到新 prepend 的更旧一页，随即被 `jumpTo(savedPixels + delta)` 拽回加载前视口，形成「到了新数据窗口又跳回去」的双跳。产品选定方案 **A**：加载后留在新数据窗口，不再做原位置补偿。

## What Changes

- 触顶 / 顶部下拉触发的 `loadMore` 成功后，**不得**再执行「`savedPixels + ΔmaxScrollExtent`」式滚回加载前锚点。
- 视口应留在更旧端，使用户继续看到刚合并进来的更旧记录（通常近列表顶）。
- **BREAKING（相对旧规格文案）**：原「MUST 保持滚动位置不发生明显跳变」改为「留在新页/更旧端、禁止事后拽回」。
- 底部上拉刷新最新一页、跟底 `followLatest` 行为不变。
- 不新建 `**/test/**`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-history-pagination`：改写「较旧方向加载更多」的滚动验收——A：留新页，禁双跳拽回。

## Impact

- 代码：`app/lib/ui/home_history_scroll.dart` 的 `_handleLoadMore`（移除 post-frame `jumpTo` 补偿）。
- 规格：`home-history-pagination` delta；对照基线 `openspec/specs/v2.1.4.md`。
- 无 HTTP / 无预测 / 无原生变更。
