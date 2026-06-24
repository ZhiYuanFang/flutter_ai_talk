## Context

`HomeHistoryScroll` 使用正向 `CustomScrollView`（最新在底部，日期 header 吸顶在顶部）。已有：

- 顶部 `RefreshIndicator` → `_handleRefresh`：触顶且 `hasMore` 时 `loadMoreHistory`，否则 `refreshFromRemote`。
- `HomeHistoryNotifier.refreshFromRemote`：拉取 page=1，更新内存与磁盘快照。
- `followBottomThreshold = 96` 判定近底；`scrollToBottom` 锚定最新。

用户选定：**在底部附近上拉超过阈值后松手**才刷新最新。

## Goals / Non-Goals

**Goals:**

- 底部近底 + 上拉累积 ≥ 阈值（建议 **72px**）+ 松手 → `onRefresh()` / `refreshFromRemote()`。
- 刷新中防重复触发；完成后 `scrollToBottom(force: true)` 并保持 `_followLatest`。
- 底部轻量指示（文案或 spinner），让用户感知拉动进度。

**Non-Goals:**

- 不改顶部 RefreshIndicator 与 loadMore 语义。
- 不新增后端 API；不改动 WS merge 规则。
- 不为 Web 单独分支（沿用 `AlwaysScrollableScrollPhysics`；真机/浏览器手感差异仅作验证项）。

## Decisions

### 1. 手势检测：`NotificationListener<ScrollNotification>`

**选择**：在 `CustomScrollView` 外包 `NotificationListener`，监听 `ScrollUpdateNotification`（累积拖动）与 `ScrollEndNotification`（松手判定）。

**近底条件**：`maxScrollExtent - pixels <= followBottomThreshold`（复用 96px）。

**累积规则**：仅在近底且 `dragDetails != null` 时，累加上拉 overscroll 量；离开近底或新一轮拖动开始时清零。

**触发**：松手时若累积 ≥ `_bottomPullTriggerThreshold`（**72px**）且未在刷新中 → `await widget.onRefresh?.call()`。

**备选**：镜像 `RefreshIndicator` 到底部 — Flutter 不支持；否决。

### 2. 与顶部 Refresh 职责分离

| 位置 | 手势 | 行为 |
|------|------|------|
| 顶部 | 下拉 RefreshIndicator | 触顶 + hasMore → loadMore；否则 refresh |
| 底部 | 上拉 NotificationListener | **仅** refreshFromRemote |

### 3. 视觉反馈：末尾 `SliverToBoxAdapter`

**选择**：在 `slivers` 末尾增加高度随 `_bottomPullExtent` 变化的 footer（clamp 到阈值 1.2 倍），展示「上拉刷新 / 松开刷新 / 刷新中」。

**备选**：Stack overlay — 也可，但 footer sliver 与拉动同向扩展更直观。

### 4. ScrollPhysics

**首选**：保持 `AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics())`，靠 `ScrollUpdateNotification` 在 `pixels >= maxScrollExtent` 时累积 drag delta。

**若 Android 真机 overscroll 信号不足**：再评估底部允许少量 overscroll 的自定义 `ScrollPhysics`（仅在本 change 验证阶段决定，不预先引入新依赖）。

### 5. 刷新后列表内容

`refreshFromRemote` 将 `highestPageLoaded` 置 1、列表替换为 page1 — 与基线「刷新最新一页」一致。用户从底部主动上拉刷新即表示接受「以最新 20 条为准」。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| Android Clamping 底端 overscroll 弱 | 真机调阈值；必要时小改 Physics |
| 与顶部 refresh 语义重叠 | 文档与 spec 区分顶/底职责 |
| 飞行动画期间刷新 | `refreshFromRemote` 已有 `_flyAnimationFrozen` 排队 |
| 误触刷新 | 阈值 + 必须近底 + 松手触发 |

## Migration Plan

纯客户端交互增强，无迁移。回滚即移除底部 listener 与 footer sliver。

## Open Questions

（无 — 阈值 72px、松手触发、复用 refreshFromRemote 已确认。）
