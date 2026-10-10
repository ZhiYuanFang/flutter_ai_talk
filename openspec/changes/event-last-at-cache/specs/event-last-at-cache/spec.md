## ADDED Requirements

### Requirement: Client SHALL persist per-baby per-root latest real occurrence time

The Flutter client SHALL maintain a device-scoped local cache mapping catalog **root** `eventId` → latest real feeding occurrence instant previously observed on this device. Persistence MUST be keyed by `deviceNo` (e.g. SharedPreferences `event_last_at_v1_<deviceNo>`). The cache MUST NOT store recall-seed synthetics, MUST NOT share storage or clear-on-sample-gate logic with `PredictionRecallSeed`, and MUST NOT invent `HistoryRecord` rows. 客户端 **必须** 按 `deviceNo` 持久化目录根 → 本机曾见真喂养最新发生时刻；**不得** 写入回忆种子伪记录；**不得** 与 `PredictionRecallSeed` 混存或共用达标清理；**不得** 合成伪历史行。

#### Scenario: 按宝宝隔离

- **WHEN** 设备 A 与设备 B 先后绑定且各有不同发生时刻写入
- **THEN** 客户端 MUST 读写各自 `deviceNo` 下的 map，MUST NOT 串读另一宝宝缓存

#### Scenario: 键为目录根

- **WHEN** 一条子节点真喂养记录进入观察路径
- **THEN** 客户端 MUST 解析为目录根 eventId 后再写入/刷新该根缓存

### Requirement: Client SHALL refresh cache on real history observe and invalidate tip on delete

When real feeding history enters memory (home/range merge, successful add/update, authenticated history WS insert/update), the client MUST set `cache[root] = max(cache[root], occurrenceAt)` for that root (skipping records without a resolvable occurrence instant and skipping recall-seed synthetics). When a real record is deleted and its occurrence instant is at or after the cached tip for that root, the client MUST recompute the tip from still-visible home∪range real records for that root, or remove the cache entry if none remain. Deletes older than the tip MUST NOT clear a newer tip. 真历史入内存时 MUST 以 max 刷新；删除可能打到 tip 时 MUST 按仍可见真记录重算或清键；更早删除 MUST NOT 清掉更新的 tip。

#### Scenario: 窗外历史曾见过则保留 tip

- **WHEN** 某根记录曾进入内存并写入缓存，随后离开当前 home∪range 窗口但仍未删除 tip
- **THEN** 该根缓存条目 MUST 仍保留该发生时刻（直至被更新的 max 或 tip 失效逻辑改变）

#### Scenario: 删除 tip 后窗口仍有更早记录

- **WHEN** 用户删除该根当前缓存 tip 对应记录，且 home∪range 仍有该根其它真记录
- **THEN** 客户端 MUST 将缓存更新为仍可见真记录中的最新发生时刻

#### Scenario: 删除 tip 后窗口无该根记录

- **WHEN** 用户删除该根缓存 tip 且乐观同步后 home∪range 该根无真发生
- **THEN** 客户端 MUST 移除该根缓存键

### Requirement: Prediction row lastAt MUST fall back to cache on window miss

When building hot smart-prediction rows, `SmartPredictionRow.lastAt` MUST be `latestOccurrenceAtForRecords(windowRecords) ?? cache[root]`. A non-null value from either source MUST count as real `lastAt` for「上一次」copy and for forecast-on CTA / card-tap branches that gate on `lastAt == null`. The client MUST NOT treat cache miss + window miss as proof the event never occurred beyond showing「暂无」/supplement affordances already specified. 组行 `lastAt` MUST 为窗口最新 ?? 缓存；任一非空 MUST 视为真 lastAt 供文案与有无 lastAt 分支；两者皆无时保持既有「暂无」/补充流。

#### Scenario: 窗口未命中用缓存展示

- **WHEN** 热态某根在 home∪range 无真记录，但该 `deviceNo` 缓存有该根时刻 T
- **THEN** 该卡 `lastAt` MUST 为 T，「上一次」MUST 展示 T 的本地可读文案（不得为「暂无」）

#### Scenario: 窗口命中优先于更旧缓存

- **WHEN** 窗口最新真发生为 T2，缓存为更早的 T1
- **THEN** 该卡 `lastAt` MUST 为 T2

#### Scenario: 仅缓存时不开放编辑 Sheet

- **WHEN** 卡上 `lastAt` 仅来自缓存且 home∪range 无法解析该根真 `HistoryRecord`
- **THEN** 「上一次」文案 MUST NOT 打开 `showHomeHistoryEditSheet`
