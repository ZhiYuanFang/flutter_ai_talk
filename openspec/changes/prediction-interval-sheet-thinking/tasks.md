## 1. 专用间隔 Sheet 与两态

- [x] 1.1 将 `pickRecallIntervalMinutes` 改为专用 glass Sheet（picking / thinking），不改通用 `showGlassSingleWheelPickerSheet`
- [x] 1.2 picking：保留 logo+「·大概多久一次」标题、15min 步进滚轮、确定/取消
- [x] 1.3 确定：校验间隔 → upsert 种子（回调或 Sheet 内 Consumer）→ 切 thinking；标题改为「大概 {间隔} 一次」；隐藏滚轮

## 2. 思考打字机与按钮 A

- [x] 2.1 实现逐字展示（约 42ms）；主段叙事 + 播完后加粗自适应说明行
- [x] 2.2 未播完主按钮「跳过动画」；全文后「关闭」dismiss Sheet
- [x] 2.3 可选抽出 typewriter helper；不强制删 OnboardingPanel

## 3. 卡片衔接与验收

- [x] 3.1 `_onPickIntervalRecall` 与新 Sheet 返回值/副作用对齐（避免重复 upsert）
- [x] 3.2 手工：确认→思考→关闭；跳过动画；种子与 countdown；通用其它滚轮未回归
- [x] 3.3 不新建 `**/test/**`

## 4. 思考完毕状态与重选（续写）

- [x] 4.1 传入 `lastAt`；播完后状态行改为「思考完毕 · 下一次{事件名}：{时刻}发生」（nextAt≈lastAt+interval）
- [x] 4.2 点状态行同层回 picking 重选间隔；未播完仍为「正在思考…」不可点
- [x] 4.3 手工：播完文案、点重选、再确认再思考、关闭
