## 1. 底部上拉手势（`home-history-pagination`）

- [x] 1.1 在 `HomeHistoryScroll` 用 `NotificationListener<ScrollNotification>` 检测近底上拉，定义阈值常量（建议 72px）与 `_bottomPullExtent` 状态
- [x] 1.2 松手时：近底且累积 ≥ 阈值 → `await widget.onRefresh?.call()`；否则清零；刷新 in-flight 时忽略
- [x] 1.3 离开近底或新拖动开始时清零累积，避免误触

## 2. 底部视觉反馈

- [x] 2.1 在 `CustomScrollView` slivers 末尾增加 footer（高度随拉动变化），展示「上拉刷新 / 松开刷新 / 刷新中」
- [x] 2.2 刷新完成后调用 `scrollToBottom(force: true)` 并保持 `_followLatest`

## 3. 验证

- [ ] 3.1 底部上拉超过阈值松手 → 触发 page=1 请求，最新记录更新
- [ ] 3.2 未达阈值或非近底上拉 → 不请求
- [ ] 3.3 顶部下拉触顶 loadMore / 非触顶 refresh 行为与改前一致
- [ ] 3.4 Android 真机底端上拉手感可接受（必要时记录 Physics 微调 follow-up）
- [x] 3.5 `flutter analyze` 无新增 error（`home_history_scroll.dart`）
