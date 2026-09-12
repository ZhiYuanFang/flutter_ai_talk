## 1. 统一推演入口（间隔分岔）

- [x] 1.1 扩展 `event_next_predictor`（或薄封装）：`lastAt` 仅真记录；达标→加权中位，否则→`seed.interval`；无真 `lastAt` 不预测
- [x] 1.2 `buildSmartPredictionRows` / provider：传入真历史 + seeds map；停止向推演喂 merge 伪历史；图表过去点仅真记录
- [x] 1.3 退役预测路径对 `mergeHistoryWithRecallSeeds` / `syntheticHistoryRecordsFromSeed` 的调用（可删或废弃）

## 2. lastAt 同源与空库清种子

- [x] 2.1 `SmartPredictionRow.lastAt` 与编辑同源（home∪range 真记录）；预测 `lastAt` 对齐
- [x] 2.2 该 root 真记录为空时 `clearSeeds`；不得再出种子 countdown
- [x] 2.3 `home.removeRecord`（成功删）同步从 range 快照去掉同 id；保留 debounce 重拉

## 3. per-card 种子与消费者

- [x] 3.1 间隔确认仍 upsert 种子；生效改为读 `seed.interval`，不依赖合成点喂 predictor
- [x] 3.2 核对 tip / 小组件 / timeline 等同用统一行预测；CTA 门闸基于真 `lastAt`

## 4. 验收

- [x] 4.1 手工：充分样本走中位；1 真+种子走 `lastAt+seed.interval`；无真不预测
- [x] 4.2 手工：改「上一次」卡文案立刻对齐；删光→暂无+无 countdown+种子清除
- [x] 4.3 `dart analyze` 相关文件；不新建 `**/test/**`；本 change 无 `app/android/**` 必改
