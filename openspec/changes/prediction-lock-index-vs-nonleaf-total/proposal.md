## Why

联调 Go `invite-peer-force-ucg` 时发现：预测「永久条数」同时驱动**列表锁槽**与 Hub「已全部激活」，但两端集合不同——锁按当前展示排序下标，天花板来自字典非叶子数。若不把产品决议写进规格，后续易被服务端 design 中「锁槽与 total MUST 同一非叶子集合」带偏，或误改成按事件 ID 绑死槽位。

## What Changes

- 明确产品语义：**「已激活 N 个」解锁当前预测列表排序后的前 N 行**（槽位，非固定 eventId）。
- 明确 **「已全部激活」仅对齐 catalog `totalActivatableCount`**（Go device 字典非叶子总数）；客户端不得用可见行数重算天花板。
- 接受两集合故意解耦带来的边角（可见行已全开但 Hub 未全部激活时可继续 +1；重排后槽位对应事件可变）。
- 对照现实现做审计与注释对齐；预期无破坏性 API 变更，无服务端改动。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-vip-overlay-client`：锁槽语义澄清为「当前排序列表 display index」；重排后仍按下标与 `allowedCount` 比较。
- `feature-unlock-hub-prediction`：「已全部激活」必须使用服务端非叶子 `totalActivatableCount`；不得用客户端可见预测行数替代。

## Impact

- Flutter：`smart_prediction_screen` 锁逻辑、`feature_unlock_hub_screen` / `feature_unlock_models` 徽章与 CTA 门闸；可能仅注释/规格同步。
- 依赖已落地 Go catalog `totalActivatableCount`（非叶子计数）；本变更不改兄弟仓。
- 叠加未归档 change `invite-peer-force-ucg`；归档时须一并保留本 delta 语义。
- 不新建测试文件。
