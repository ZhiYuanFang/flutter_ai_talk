## 1. 折叠尾部窗口

- [x] 1.1 重构 `_ThinkingBlock` 折叠分支：`SizedBox` + `ClipRect` + `Align(bottomLeft)` 展示完整 `Text`，固定高度 `5 × lineHeight`
- [x] 1.2 流式思考阶段不折叠、全文展示；`answer_delta` 开始后自动 `thinkingExpanded = false` 再折叠

## 2. 溢出检测与展开态

- [x] 2.1 用 `TextPainter`（与展示同 `TextStyle`、气泡可用宽度）测量全文高度，驱动 `hasVisualOverflow`、「点击展开」与顶部渐变
- [x] 2.2 展开态使用 `SingleChildScrollView` 展示全文；点击切换 `thinkingExpanded` 行为保持不变

## 3. 移除折叠态滚动 pin 状态机

- [x] 3.1 删除 `_ChatItem.thinkingInnerPinned`、`onInnerPinChanged` 回调及折叠态 `ScrollController` / `_scrollToLatest` / `_onInnerScroll` /「跟随最新」`ActionChip`
- [x] 3.2 清理 `pangbao_ai_screen.dart` 中相关 `setState` 与未使用字段

## 4. 验证

- [ ] 4.1 Web：流式 thinking/answer 时列表跟底；上滑后出现中部向下箭头，点击回到底部并恢复跟底
- [ ] 4.2 长段落无 `\n` 时出现「点击展开」；展开后可见全文并可内滚
- [ ] 4.3 折叠流式过程标题行无「跟随最新」chip
- [ ] 4.4 进入页面 `session_sync` 后自动滚到最新记录；发送新问题重置跟底
