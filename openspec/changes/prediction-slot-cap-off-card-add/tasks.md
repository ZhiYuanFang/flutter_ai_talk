## 1. 槽位开启数对齐

- [x] 1.1 实现热态非 VIP 对齐：`enabledCount > allowedCount` 时关闭任意超额已开项并持久化；`enabledCount < N` 不自动开；VIP / allowedCount 全量哨兵 / demo 骨架跳过
- [x] 1.2 对齐触发接入 VIP settle 之后；single-flight + 幂等 no-op + 自触发 ignore，避免 prefs 写回抖死循环
- [x] 1.3 确认未改动 `buildSmartPredictionRows` 排序与预测算法路径

## 2. 关推演点卡加事件

- [x] 2.1 调整 `addEventTapFor`：关推演且非计时 → 整卡可点且永远 `EventRecordIntent.add`；开推演保持 supplement/add 原分支
- [x] 2.2 确认关推演仍不展示「补充上一次」/间隔 CTA；「上一次」编辑路径不变

## 3. 回归闸门

- [x] 3.1 确认满额再开仍走 `_requestForecastToggle` 弹框 → `/features/unlock`；关开关始终成功

## 4. 手工验收

- [ ] 4.1 新用户/空 disabled：非 VIP allowedCount=N 时热态开启数 ≤ N；加购后不自动多开
- [ ] 4.2 降级/减小 N：超额被裁到 ≤ N；VIP 不裁；骨架全开
- [ ] 4.3 关推演：点卡 add（无 lastAt 也不走 supplement）；开推演无 lastAt 仍 supplement；「上一次」可编辑
