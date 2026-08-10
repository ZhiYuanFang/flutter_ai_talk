## Why

已绑定宝宝但喂养历史不足时，本地预测算法（约需同一根事件 ≥3 次发生、≥2 个 ≥15 分钟间隔）无法出结果，智能预测主页只剩「暂无可用预测数据」。需要在不污染喂养时间线的前提下，用轻量「回忆」引导采集上次时刻与间隔，合成仅供推演的种子，并让用户感到系统在按其情况量身定做。

## What Changes

- 进入智能预测页时，按**根事件缺口**排队：凡 `parentId == null` 且真历史尚未达到推演样本门槛的根，进入量身定做引导。
- 引导为预测页**内嵌**空态 PageView，每页一张**悬浮感**卡片；交互仅按钮 / 滚轮（到分钟），禁止键盘手输。
- 每卡采集：上次发生时刻（`time` 型记**结束**时刻）+ 间隔 + 叶子选择；无子节点的根仅展示根自身一钮；可跳过（跳过则关闭该根推演）。
- 样本策略 C：用上次 + 间隔合成推演用发生点；写入**独立预测种子存储**，**不得**作为喂养/历史记录上报或展示。
- 真历史追上该根算法门槛后，**立即丢弃**该根种子。
- 每答完一卡播放一段结合填写内容的**慢速逐字思考**；队列空后收尾 CTA「体验胖宝智能预测」，关闭空态，展示正常预测 UI。
- 预测管道在内存中合并「真历史 ∪ 种子」供 `buildSmartPredictionRows` / predictor 使用。

## Capabilities

### New Capabilities

- `prediction-recall-onboarding`：缺口判定、悬浮卡 PageView、采集交互、跳过、逐卡思考文案、收尾 CTA。
- `prediction-recall-seeds`：预测专用种子存储、合成发生点、与喂养历史隔离、真历史追上后丢弃、供预测 merge。

### Modified Capabilities

- `smart-prediction-page`：数据不足时展示内嵌量身定做空态；种子/历史合并后展示正常预测列表。

## Impact

- **UI**：`SmartPredictionScreen` 空态层；新建回忆卡片 / 思考打字机组件。
- **状态**：新本地 store + Riverpod；复用 `ForecastToggleStore` 处理跳过关推演。
- **预测**：`smartPredictionRowsProvider`（或等价）merge 种子；不改网关 history API 契约。
- **测试**：不新建 `**/test/**`；手工验收缺口卡、跳过、种子不进喂养、追上丢种子、思考与 CTA。
