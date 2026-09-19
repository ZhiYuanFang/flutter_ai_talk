## 1. 提问阶段重开

- [x] 1.1 `asking` 且已开通时，正文下方展示「重新预测」（复用 `_GrowthBodyCta`，带用量小字），点击 `_onPredict(restart: true)`
- [x] 1.2 按钮放在题目与选项之外；`streaming` / `loadingLatest` 仍不展示
- [x] 1.3 不改 `startPredict` / Go / Python；不在 restart 开始时清空已有 `resultMarkdown`

## 2. 验收

- [ ] 2.1 手工：提问中可见「重新预测」，点击后题目消失并进入新一轮思考；思考中无该按钮；失败且已有旧结果时回到旧结果
- [x] 2.2 确认未新建 `**/test/**`；不改 `app/android/**`、Go、Python
