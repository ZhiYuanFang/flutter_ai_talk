## 1. missAnchor 存储与预测

- [x] 1.1 本机按根持久化 / 读取 / 清除 `missAnchor`（随账号 wipe）
- [x] 1.2 `predictNextForEventKey` 支持可选 miss 锚：亲和钟点锚 + `nextAt = missAnchor + interval`；展示 `lastAt` 仍为真 tip；直方图不含 miss
- [x] 1.3 行组装注入 missAnchor；真 tip ≥ 锚时清除

## 2. UI

- [x] 2.1 非预约热态逾期卡展示「跳过本次」；点击写入当前 nextAt 为锚并刷新；busy 防连点
- [x] 2.2 未逾期 / 预约 / 无 pred / 关推演不展示；不走 hero-skip

## 3. 验收

- [ ] 3.1 手工：逾期跳过 → nextAt 前移；再记真发生 → 锚清除；不新建 `**/test/**`
