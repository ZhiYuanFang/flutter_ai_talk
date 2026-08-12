## 1. 传列与门控

- [x] 1.1 `_WaterfallCards`：`itemBuilder` 传入列/行索引；分列逻辑保持 `i % columnCount`
- [x] 1.2 预测页计算 `phoneLandscape`（landscape && shortestSide < 600）；平板不启用侧 logo

## 2. 卡片布局

- [x] 2.1 `_PredictionEventCard`：`titleInlineLogo = phoneLandscape && rowIndexInColumn > 0`（**首行大图 / 后续行侧 logo**；纠正原 `columnIndex > 0`）
- [x] 2.2 `logoAnchorKey` 与 soonest `_HeartbeatLogo` 挂在当前可见 logo 上
- [x] 2.3 计时中卡：不破坏既有标题旁 logo

## 3. 验收

- [ ] 3.1 手机横屏：第一行（每列顶卡）大图、第二行及以后侧 logo 且更矮；竖屏无回归
- [ ] 3.2 平板横屏：各卡仍为大 logo
- [x] 3.3 未引入裸 `print`/`debugPrint`；未新建 `**/test/**`
