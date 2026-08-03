## 1. 状态与出现条件

- [x] 1.1 调整 `TipContent.shouldShow`（或等价）：thinking/answer 去空白非空才可见；空 streaming 不占位
- [x] 1.2 `dismiss` 允许 streaming 与 done；关闭后忽略该次旧 SSE 迟到事件（generation / 等价）
- [x] 1.3 `startStreaming` 重置时 bump `presentationGeneration`（或等价），供 UI 再播入场

## 2. 居中卡片 UI

- [x] 2.1 `home_screen`：tip 挂载改为内容区居中；移除非必要顶条 `Positioned`；空白区不挡历史点击
- [x] 2.2 重写 `HomeTipPanel`：不透明卡片、下方「关闭」「对话」、删除 ✕ 与整卡进陪伴
- [x] 2.3 入场：scale 弹性动画；`disableAnimations` 时跳过；增量文本不重复整段入场
- [x] 2.4 「对话」仅 done 可点 → `requestPage(companion)`；「关闭」调用 dismiss

## 3. 验收

- [ ] 3.1 手工：有思考即居中弹出弹性；done 后 Markdown；关闭/对话位置与行为正确
- [ ] 3.2 手工：点卡片外历史仍可操作；thinking 可关且旧流不回弹；展示中再添加 → 换内容再弹
- [x] 3.3 未改 `app/android/**` 则无需 release APK
