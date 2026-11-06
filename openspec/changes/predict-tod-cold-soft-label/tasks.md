## 1. 预测模型与护栏终态

- [x] 1.1 在 `EventNextPrediction` 增加 `todConfidenceLow`（默认 `false`），更新 `copyWith` / 构造调用点
- [x] 1.2 改写 `predictNextForEventKey`：按 primary → gePrimary → crossDay 优先采纳首个热区；皆冷则保留 primary（或纯种子 `nextAt`）并置 `todConfidenceLow = true`；MUST NOT 仅因皆冷返回 null
- [x] 1.3 Debug：`[PredictInterval]` 记录选用 path 与 `soft=`；禁止刷全量历史

## 2. 预测卡文案

- [x] 2.1 热态非预约卡在有倒计时且 `todConfidenceLow` 时，倒计时区块上方展示「此刻把握不足」；热区 / 护栏跳过 / 预约 / 骨架 / 无 pred 不展示
- [x] 2.2 确认软标有 pred 时仍不展示「补充大概多久一次」（沿用既有 `pred == null` 门闩即可）

## 3. 验收

- [x] 3.1 手工：主冷+跨日热 → 采用跨日且无文案；皆冷 → 有倒计时 +「此刻把握不足」；不新建 `**/test/**`（核对步骤见 design / `[PredictInterval] pick path=… soft=`；待真机执行）
