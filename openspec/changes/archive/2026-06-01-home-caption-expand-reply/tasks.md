## 1. 字幕组件

- [x] 1.1 `HomeInputCaption` 增加 `expandable`、`onExpand`；`TextPainter` 检测 3 行截断
- [x] 1.2 截断且 `expandable` 时显示可点击态（`InkWell` + 展开提示）
- [x] 1.3 新增 `showHomeReplyBottomSheet(context, text)`（可滚动 `SelectableText`、拖动手柄）

## 2. 首页布局与接线

- [x] 2.1 底部 `Stack`：字幕 `Positioned` 置于全屏 `Listener` **之上**；输入列仅保留球/键盘区
- [x] 2.2 `HomeScreen`：仅当当前字幕为 `_chatReply` 时 `expandable: true`，`onExpand` 打开 BottomSheet
- [x] 2.3 语音模式与文字模式共用同一字幕层，移除 Column 内重复 `HomeInputCaption`

## 3. 验证

- [x] 3.1 长服务端回复：字幕省略号 + 点击弹出 BottomSheet 全文
- [x] 3.2 转写 partial 很长：不可点击展开
- [x] 3.3 短回复：无展开点击
- [x] 3.4 点击字幕不触发按住录音；滑出取消仍正常
