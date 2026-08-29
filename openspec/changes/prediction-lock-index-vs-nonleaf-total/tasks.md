## 1. 语义审计

- [x] 1.1 核对预测页锁：`realIndex < allowedCount`（+ VIP OR）基于当前排序列表下标，非 eventId 绑定
- [x] 1.2 核对 Hub：「已全部激活」仅用服务端 `totalActivatableCount`；CTA 门闸与 `isPredictionFullyActivated` 一致

## 2. 注释与文档对齐

- [x] 2.1 在锁判定 / `predictionIndexUnlocked` / Hub 徽章相关处补简短中文注释，标明槽位 vs 非叶子天花板
- [x] 2.2 若 `invite-peer-force-ucg` 仍未归档：在其 `design.md` Risks 增一句交叉引用本 change（可选，避免双源冲突）

## 3. 验收

- [x] 3.1 手工路径：allowedCount=N 时仅前 N 行可点；重排后槽位跟下标；Hub 在 N 未达 total 时不显示「已全部激活」
- [x] 3.2 `openspec validate prediction-lock-index-vs-nonleaf-total --strict`
