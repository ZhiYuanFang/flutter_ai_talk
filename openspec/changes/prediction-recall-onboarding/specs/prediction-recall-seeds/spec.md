## ADDED Requirements

### Requirement: Recall seeds SHALL exist only for prediction and never as feeding history

The client SHALL persist per-root recall seeds (last time, interval, leaf id, and synthesized occurrence instants) in a store dedicated to prediction. Seeds MUST NOT be written through the feeding history add API, MUST NOT appear as rows in the feeding home timeline, and MUST NOT be uploaded as user history events solely because they are seeds.

回忆种子 **必须** 仅存于预测专用存储；**不得** 经喂养加事件 API 写入，**不得** 出现在喂养时间线，**不得** 仅因种子身份被当作历史事件上报。

#### Scenario: 确认卡片不产生喂养行

- **WHEN** 用户在量身定做中为根事件 A 确认回忆并生成种子
- **THEN** 喂养主页历史列表 MUST NOT 因此新增 A 的记录行
- **AND** 本地预测种子存储 MUST 含 A 的种子数据

### Requirement: Seed synthesis SHALL satisfy predictor sample gate from last time and interval

Given a confirmed last occurrence time and an interval of at least 15 minutes, the client SHALL synthesize at least three occurrence instants for that root (stepping backward by the interval from the last time) so that the local predictor can obtain at least two intervals of ≥15 minutes. For `time`-typed roots, the last time MUST be treated as the last **end** instant.

确认上次时刻与 ≥15 分钟间隔后，客户端 **必须** 自上次时刻按间隔向前回推合成至少三个发生点，以满足推演样本门槛；`time` 型上次时刻 **必须** 视为结束时刻。

#### Scenario: 合成三点

- **WHEN** 用户确认上次时刻 T 与间隔 D（D≥15 分钟）
- **THEN** 该根种子 MUST 包含至少 T、T−D、T−2D 三个发生时刻（或等价满足门槛的集合）

### Requirement: Prediction pipeline SHALL merge seeds with real history in memory

When building smart prediction rows / upcoming predictions, the client SHALL merge real range history with in-memory records derived from active seeds for roots that still need them. Merge MUST NOT persist those synthetic records into the history repository.

构建智能预测时，客户端 **必须** 在内存中合并真历史与有效种子派生记录；**不得** 将合成记录持久化进历史仓储。

#### Scenario: 仅有种子也可出预测行

- **WHEN** 根事件 A 无真历史但存在有效种子且推演未关闭
- **THEN** 智能预测列表 MUST 能为 A 生成行（在算法可计算出 nextAt 的前提下）

### Requirement: Real history catching up SHALL discard that root seed immediately

When real history for a root event meets the predictor sample gate, the client MUST delete that root’s recall seed immediately and MUST stop using seed synthetic points for that root.

当某根真历史已达推演样本门槛时，客户端 **必须** 立即删除该根种子，并 **必须** 停止对该根使用种子合成点。

#### Scenario: 追上丢种子

- **WHEN** 根事件 A 曾有种子，且随后真历史发生点已使 A 达到推演样本门槛
- **THEN** A 的种子 MUST 被删除
- **AND** 后续预测 MUST 仅使用 A 的真历史（不再 merge A 的种子）
