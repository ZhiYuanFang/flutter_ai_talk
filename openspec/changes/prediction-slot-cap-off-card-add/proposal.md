## Why

新用户绑定宝宝后，推演开关默认全开，`enabledCount` 可超过永久 `allowedCount`，槽位闸只拦「再开」不纠正存量，导致授权不足仍展示超额预测表面。同时关推演后整卡点击被置空，用户只能点「上一次」编辑，记账与推演开关被错误耦合。需要在 UI/权益层强制开启数 ≤ 槽位，并恢复关推演时点卡快速记账。

## What Changes

- **非 VIP**：当热态 `enabledCount > allowedCount`（含默认全开、降级、槽位变小）时，客户端 **必须** 将超额推演关闭并持久化，使开启数 ≤ `allowedCount`；超额关谁 **任意**（确定性即可，不绑定产品排序语义）。
- **只关不补**：`enabledCount < allowedCount` 时 **不得** 自动 `setEnabled(true)` 凑满槽位；加购后由用户手动开。
- **VIP** / `allowedCount` 全量哨兵：不强制裁剪；可保持默认全开。
- **骨架**（未登录/未绑定 demo）：继续全开演示，不跑槽位裁剪。
- **不得** 改列表排序比较器、**不得** 改预测算法（nextAt / 间隔 / 图表数据）。
- **关推演点卡**：**BREAKING（相对 catalog-complete）** — 热态关推演时整卡点击 **必须** 走 `EventRecordIntent.add`（含无 `lastAt`），**不得** 走 supplement 补齐引导；补齐 CTA 关推演时仍不展示；「上一次」编辑路径不变。
- **废止** `prediction-toggle-slot-gate` design D5「不自动关闭超额已开启项」在非 VIP 下的行为。
- 时间颜色等视觉议题 **不在** 本变更范围。

## Capabilities

### New Capabilities

- `prediction-slot-enabled-cap`：非 VIP 热态强制 `enabledCount ≤ allowedCount`；只关不补；VIP/骨架豁免；不改排序与预测算法。
- `prediction-off-card-add`：关推演整卡点击永远 `add`，与开推演时的 supplement/add 分支解耦。

### Modified Capabilities

- `prediction-toggle-slot-gate`：满额「再开」闸保留；超额存量改为由 `prediction-slot-enabled-cap` 强制对齐（不再保留超额已开）。
- `smart-prediction-page`：废止「关推演点卡不得加事件/补齐」中与整卡 `add` 冲突的约束；关推演仍不得展示补齐 CTA。

## Impact

- Flutter：`forecast_toggle_*`、`smart_prediction_screen.dart`（`addEventTapFor` / 槽位对齐）、可能轻量 provider listen（single-flight）。
- 小组件 sync：disabled 集合变化后预测展示随之减少（预期内）。
- 叠加/废止：`prediction-toggle-slot-gate` D5；`prediction-catalog-complete-cards` 关推演 `onCardTap` 置空。
- 不新建 `**/test/**`；不改 Android/R8；不改服务端 catalog 字段。
