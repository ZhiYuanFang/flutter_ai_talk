## 1. 状态角色

- [x] 1.1 `LandscapeVoiceUiState` 增加显式思考标记（enum `subtitleKind` 或 `subtitleIsThinking`）
- [x] 1.2 `thinking_delta` → thinking；`answer` → answer；ASR/「我在」/退下等 → 非 thinking；`_clearSubtitle` 复位

## 2. 弹幕样式与脉冲

- [x] 2.1 `_LandscapeVoiceSubtitleToast` 接收思考标记；思考用 `textOnPanelGlassMuted`，否则满对比 `textOnPanelGlass`
- [x] 2.2 思考态慢弱循环 opacity 脉冲（约 1.2–1.8s，弱幅）；离开 thinking 停止并恢复稳定透明度
- [x] 2.3 预测页传入状态标记；换思考字不无故重启脉冲相位

## 3. 验收

- [ ] 3.1 真机：思考浅字+脉冲；答案满对比且停脉冲；ASR/「我在」不脉冲
- [x] 3.2 确认经 `AppColor` 取色；未引入裸 `print`；未新建 `**/test/**`；未改 WS/`\r` 逻辑
