## Context

智能预测热态卡的 `SmartPredictionRow.lastAt` 今日仅来自 `predictionRealHistoryProvider`（home 预加载 ∪ 预测 range）上 `latestOccurrenceAtForRecords`。窗外的真实上次发生会被判成 `null` →「暂无」/开推演「补充上一次」。已有 `PredictionRecallSeed` 会在样本达标或空库策略下清理，且其 `lastAt` 不得作推演锚点，不能兼做「展示用上次时间」。

本变更在客户端增加 **deviceNo × 目录根 eventId → 最近真发生时刻** 本地缓存，写于真历史入内存路径，读于组行（及同源「有无 lastAt」分支）；不扩分页、不加新 HTTP。

## Goals / Non-Goals

**Goals:**

- 持久化本机曾见过的真喂养最新发生时刻，按宝宝隔离。
- 组行：`lastAt = 窗口 latest ?? 缓存`；「上一次」文案与 CTA/点卡「有无 lastAt」同源。
- 缓存时刻视为真 `lastAt`（可作种子间隔推演锚点）；仍不得用 `PredictionRecallSeed.lastAt` 顶替。
- 删除可能打到缓存 tip 时失效/按仍可见记录重算；与回忆种子 store 解耦。

**Non-Goals:**

- 新服务端「每事件最近一次」接口；强制加长 range / 加大 home pageSize。
- 把缓存合成伪 `HistoryRecord` 进间隔样本统计。
- 缓存命中但窗口无对应记录时开放「上一次」编辑 Sheet（仍须能解析到真 `HistoryRecord`）。
- 改 Go / Redis / pending 协议。

## Decisions

### 1. 存储形态：SharedPreferences JSON，按 deviceNo 分 key

- Key：`event_last_at_v1_<deviceNo>`；值为 `{ "<rootEventId>": "<ISO8601 UTC>" }`。
- 选 SharedPreferences：与 `PredictionRecallSeedStore` / 画像 prefs 一致，无新依赖；map 体量小（根事件数级）。
- 备选：SQLite / 文件 — 过重，拒绝。

### 2. 键为目录根 eventId

- 与卡、`smart_prediction_rows`、预约/种子根一致；写入前经既有 `rootEventIdForCatalog`（或等价）解析。
- 子节点记录必须归并到根再 `max`。

### 3. 写：观察真记录时取 max；删 tip 时重算/清键

| 触发 | 行为 |
|------|------|
| home/range 合并、WS 入列、新增/改时间成功 | 对该根 `cache = max(cache, occurrenceAt)`（排除回忆种子伪记录、进行中未结束计时若无发生时刻） |
| 删除记录且其发生时刻 ≥ 当前缓存 tip（或相等容差） | 用当前 home∪range 仍可见真记录重算；若无可见 → **remove** 该根键 |
| 删除且发生时刻明显早于 tip | 不改缓存 |
| 切换/清空 deviceNo、wipe 本地态 | 不读错宝宝；wipe 路径清理对应该 device 的 prefs key |

冷启动窗口为空但缓存仍在 → 展示缓存（本变更要解决的主路径）。

### 4. 读：仅组行 / 展示与「有无 lastAt」；间隔样本仍只用窗口记录

- `buildSmartPredictionRows`（或紧邻包装）：`windowLast ?? cache[root]`。
- `predictAllUpcoming` 的锚点 `lastAt`：与行一致可用缓存（有种子间隔时才能 `nextAt`）；**不得**因缓存伪造多样本。
- 「上一次」可点编辑：仍要求窗口内能解析到真 `HistoryRecord`；仅缓存命中 → 展示时刻但不可点编辑。

### 5. 与 PredictionRecallSeed 隔离

- 独立 store / provider；不得共用 clear-on-sample-gate 逻辑。
- 删光 tip 清缓存后，既有「清该根 seed」规则仍适用；清 seed **不得**顺带误清其它根的 lastAt 缓存。

### 6. Provider 形态

- `Notifier`/`AsyncNotifier` 持有 `Map<String, DateTime>`（当前 deviceNo）；deviceNo 变化 reload。
- 历史 notifier 成功路径调用 `observe`/`invalidateTip`；组行 `ref.watch` 缓存 map。
- Debug：复用既有 home/prediction 相关 tag 或极少量日志；新 tag 须三联改（本变更默认不新增 tag，除非排查必需）。

## Risks / Trade-offs

- [缓存陈旧：本机未见过的他端删除] → 仅删 tip 时清键；他端删光而本机窗口长期无该根记录时可能残留 → 可接受；用户本机删 tip 或日后拉到更新记录会 `max`/失效纠正。
- [换机无缓存] → 冷机仍可能「暂无」，与今日一致；不宣称跨设备同步。
- [误把种子当真写] → 写入路径显式跳过 `isPredictionRecallSeedRecord`。
- [仅缓存 lastAt 开启补充流消失但仍无预测] → 有种子间隔则可 countdown；无间隔仍走「补充大概多久一次」（与有窗 lastAt 一致）。

## Migration Plan

- 无服务端迁移；首次安装空 map。
- 回滚：移除读兜底即可恢复「仅窗口」行为；prefs 残留无害。

## Open Questions

- 无（选项 A 已确认：本地 deviceNo×根 eventId 缓存，不新开 HTTP）。
