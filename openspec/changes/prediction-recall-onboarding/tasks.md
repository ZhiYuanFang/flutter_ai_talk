## 1. 预测种子与缺口判定

- [x] 1.1 实现 `PredictionRecallSeedStore`（按根持久化 lastAt/interval/leaf/合成点）及合成逻辑（≥3 点、间隔≥15m）
- [x] 1.2 实现与算法同源的根事件缺口判定（全部 `parentId==null`；跳过关推演者不入队）
- [x] 1.3 真历史达门槛时立即 `clearSeed`；预测管道内存 merge 种子伪记录（不写喂养仓储）
- [x] 1.4 更新 `smartPredictionRowsProvider`（或包装层）使用 merge 后历史

## 2. 量身定做 UI

- [x] 2.1 智能预测页主区嵌入悬浮卡 PageView 空态（有缺口时展示）
- [x] 2.2 单卡：分钟滚轮上次时刻（time=结束文案）+ 间隔滚轮 + 叶子按钮（无子则根自身一钮）+ 跳过；禁止文本输入
- [x] 2.3 确认后逐卡慢速逐字思考（插值本卡内容）；跳过短提示且不播长思考
- [x] 2.4 队列空收尾 + CTA「体验胖宝智能预测」关闭引导并展示正常预测

## 3. 验收

- [x] 3.1 手工：空历史引导、有子/无子叶子、跳过关推演、种子不进喂养时间线、记真历史后丢种子、再次缺口再引导
- [x] 3.2 未改 `app/android/**` 则跳过 release；若触及原生再补 `flutter build apk --release` 与 proguard
