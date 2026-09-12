## Context

推演开关经 `ForecastToggleStore` 仅持久化「关闭」集合，缺省/空集 = 全开。`prediction-toggle-slot-gate` 仅在 off→on 时按 `enabledCount` vs `allowedCount` 拦截，并在 design D5 明确不自动关超额存量。新用户绑定后热态因此可展示超额预测表面。

关推演点卡：`prediction-catalog-complete-cards` 将 `addEventTapFor` 在 `!forecastEnabled` 时返回 null；与更早的「加事件 ⊥ 推演开关」冲突。产品现要求关推演仍可点卡记账，且永远 `add`。

约束：副作用写 prefs 须 single-flight / 幂等；VIP settle 后再做权益裁剪（对齐 `vip-settled-before-entitlement-gates`）；不改预测算法与列表 sort。

## Goals / Non-Goals

**Goals:**

- 非 VIP 热态：`enabledCount ≤ allowedCount`（`allowedCount >= 0`）；超额只关不补。
- 关推演整卡 → `EventRecordIntent.add`；开推演保持现有 supplement/add 分支。
- 现有满额再开弹框闸保留。

**Non-Goals:**

- 不改 `buildSmartPredictionRows` 排序、不改 `predictAllUpcoming` / nextAt / 图表。
- 不为凑满 N 自动开启推演；不规定「超额关谁」的产品优先级（任意确定性即可）。
- 不改 Hub 库存文案、服务端 catalog、骨架全开演示、时间颜色。
- 不新建测试文件。

## Decisions

### D1：对齐 = 写 disabled，不改行构建语义

**选择**：在热态（已登录已绑定、非 demo）且 VIP 已 settle 后，若 `!isVip && allowedCount >= 0 && enabledCount > allowedCount`，从当前已开启 eventId 中任意选出超额部分 `setEnabled(false)` 并持久化，直至 `enabledCount <= allowedCount`。

**替代**：在 `buildSmartPredictionRows` 里「显示层假关」——否决，因小组件/tip 仍读真实 disabled，且开关 UI 会与展示不一致。

### D2：超额关谁任意

**选择**：实现可选「已开启列表的稳定尾部/任意子集」关闭；**不得**为此改排序或预测。验收只断言数量，不断言具体 eventId。

### D3：只关不补

**选择**：`enabledCount < allowedCount`（含加购）**不得**自动开启任何推演。

### D4：触发与治理

**选择**：在预测页或共享 notifier 上 listen `allowedCount` / VIP / rows（或 disabled 加载完成）后跑对齐；**必须** single-flight、成功幂等跳过、自触发 ignore（写 disabled 引起的 rebuild 不得重入死循环）。VIP 未 settle 前 **不得** 当非 VIP 裁剪。

### D5：豁免

- VIP 或 `allowedCount == -1`（全量哨兵，若沿用）：不裁。
- `useDemoSkeleton`：不裁，骨架继续全开。

### D6：关推演点卡

**选择**：`addEventTapFor` 在热态且非计时中：

- `forecastEnabled == false` → 始终 `EventRecordIntent.add`（含 `lastAt == null`），挂整卡 InkWell。
- `forecastEnabled == true` → 保持现状：`lastAt == null` → supplement，否则 add。

关推演仍不展示「补充上一次」/间隔 CTA。`editLastTapFor` 不变。

### D7：废止 D5（toggle-slot-gate）

非 VIP 超额存量 **不再** 保留；本 change 的对齐逻辑取代之。满额「再开」弹框逻辑保留。

## Risks / Trade-offs

- [VIP 未 settle 误裁] → 对齐前 await/依赖 VIP settle；未 settle 跳过本轮。
- [listen 写 prefs 抖动] → single-flight + 幂等（已 ≤N 则 no-op）。
- [静默关掉用户在看的卡] → 产品接受；不弹 toast（与满额开开关弹框区分）。
- [回忆 onboarding `setEnabled(true)` 绕过闸] → 若开后超额，对齐逻辑随后裁回；可选后续让 onboarding 走 `_requestForecastToggle`（本 change 非必须）。

## Migration Plan

- 随客户端发版；无服务端迁移。
- 老用户超额：首次热态对齐后写入 disabled，行为即收敛。
- 回滚：去掉对齐 listen + 恢复 `!forecastEnabled → onCardTap null`。

## Open Questions

- 无（超额关谁任意、只关不补、关推演永远 add 已确认）。
