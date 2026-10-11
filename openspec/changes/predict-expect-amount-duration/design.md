## Context

`EventNextPrediction` 与 `predictAllUpcoming` 只产出 `nextAt`。用量/用时原料已在 `historyRecordMetric`（`time`→小时时长，`number`→`eventNumber`）。预测按目录**根**聚合，喂养根下常混母乳计时与配方奶毫升。pending 现仅上报 `eventId`/`nextAt`/`title`；Go 推送基句为 `{昵称}要{title}了`。孪生仓同名 change 负责透传与追加后缀。

## Goals / Non-Goals

**Goals:**

- 根下并行维护 duration / amount 两条量线，复用间隔侧的时段桶权重与月龄半衰期加权中位思想。
- 卡片与 pending 只暴露**一条**胜出 expect；双线都过门闸时用**最近可计量模态**决胜。
- 文案统一「约」；amount 可带叶子名（如配方奶）。
- pending 结构化字段与指纹扩展；旧 Go 忽略未知字段仍可同步时间。

**Non-Goals:**

- 用量/用时 recall 种子或补充引导。
- 预约根量预测；桌面小组件 expect；改间隔算法；改 Go 基句为「即将…」。
- 新建 `**/test/**` 测试文件（除非用户另行要求）。

## Decisions

### D1：双线并行，展示择一

- **选择**：对每个非预约根，分别从 `time` / `number` 真样本建 duration、amount 线；UI 与 pending 只带胜出线。
- **替代**：根主类型单线 / 仅跟最近叶子——喂养混模态会丢另一侧信息或抖动过大。
- **理由**：量纲隔离；决胜规则简单可解释。

### D2：样本与门闸

- duration：已结束计时（`eventNumber==0` 且有效 `end-start`），值为秒；加权中位；≥2 有效样本才算有把握。
- amount：`eventNumber>0`，值为数量；单位取样本/目录 `eventUnit`/`unit`（众数或最近非空）；≥2 有效样本。
- 权重：挂在发生时刻上，复用与间隔相同的桶权重 × `recencyWeight`（同 `halfLifeDaysForBirthDate`）。
- 量线失败**不影响** `nextAt`；无胜出 expect 时卡片不占位、pending 不带 expect 字段。

### D3：双线决胜 = 最近可计量模态

- 「可计量」= 可计入 duration 或 amount 样本的真记录（进行中不计 duration）。
- 取该根最近一次可计量发生：若为 time→选 duration（须 duration 已过门闸）；若为 number→选 amount（须已过门闸）。
- 若最近模态对应线未过门闸，则回退到另一条已过门闸的线；两条都未过则无 expect。

### D4：字段与文案

客户端胜出后写入预测模型 / pending（omitempty）：

| 字段 | duration | amount |
|--|--|--|
| `expectKind` | `"duration"` | `"amount"` |
| `expectDurationSec` | 正整数秒 | 省略 |
| `expectAmount` | 省略 | 正数（整数优先） |
| `expectUnit` | 省略 | 如「毫升」 |
| `expectLeafTitle` | 省略 | 最近 amount 样本事件名（≠根名时） |

卡片次级文案示例：`预计约1小时5分钟` / `预计约120毫升`（横屏可省略叶子）。

pending 供 Go 拼后缀（客户端不拼完整 alert）：

- duration：`，预计这次约{时长}`
- amount 无叶子：`，预计这次约{量}{单位}`
- amount 有叶子：`，预计这次约{量}{单位}{叶子名}`

时长格式对齐 `formatTodayTotalAmount` / 历史用时（`N小时M分钟`）。

### D5：挂载点

- 在产出 `EventNextPrediction` 时附带可选 expect（同一次 `predictAllUpcoming` 遍历根历史）。
- 卡片读 `prediction` 上 expect；`PredictImminentRepository.syncPending` 序列化字段。
- 指纹：`eventId:nextAt:expectKind:durationOrAmount…`，空 expect 用哨兵，避免量变不 PUT。

### D6：跨仓契约

字段名与语义以本 design D4 为准；Go change 只透传与拼接，不重算。部署顺序：Go 先上（忽略未知字段兼容）或同发；旧 App 不传 expect → 仅基句。

## Risks / Trade-offs

- [混模态根抖动] → 决胜跟最近可计量；门闸不足时不展示，避免乱猜。
- [单位不一致样本] → 以非空 unit 众数/最近为准；全空则只报数字。
- [旧服务端] → omitempty JSON，时间同步仍可用；后缀需新 Go。
- [指纹变长] → 可接受；须含 expect 防漏同步。

## Migration Plan

1. 合并本仓制品与实现；联调 Go 同名 change。
2. 手工：喂养（配方奶）与睡眠（计时）各凑 ≥2 样本 → 卡上见「预计约…」→ 本机变更触发 pending → 到点推送见基句+后缀。
3. 回滚：去掉 expect 字段序列化即可；服务端忽略未知字段无害。

## Open Questions

（无；探索阶段已拍板：决胜 A、后缀统一「约」、双仓各一份提案。）
