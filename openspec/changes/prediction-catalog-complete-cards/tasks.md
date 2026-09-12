## 1. 行构建目录完备

- [x] 1.1 调整 `buildSmartPredictionRows`（或 provider）：以 `rootEvents(catalog)` 为全集出热态行；无历史根 `lastAt`/`prediction`/图表为空；尊重 `disabledForecastIds`
- [x] 1.2 确认排序：有 prediction 优先，稀疏根不丢行；`byKey.isEmpty` 不再直接 `return []`

## 2. 退役量身定做 Dialog 与空态页

- [x] 2.1 拆除 `SmartPredictionScreen` 空库自动弹 Dialog / 软关再弹 / session 启动 listen
- [x] 2.2 删除 `rows.isEmpty` 时「回忆宝宝习惯」`AppEmptyStateGallery` 与 `_HeartbeatEmptyTonalButton` 再开引导入口（catalog 有根时）
- [x] 2.3 清理卡内 `recallBlocksPerCard` / 空库优先挡 per-card CTA 的逻辑
- [x] 2.4 可选：标记或删除仅服务于 Dialog 的死入口（面板文件可留待本 change 末清理）

## 3. 卡片补齐 CTA 与原子 chrome

- [x] 3.1 派生补齐 actions：`enabled && !timing && pred==null && lastAt==null` → 心跳「补充上一次」；`… && lastAt!=null` → 既有间隔 CTA；`!enabled` → 无补齐
- [x] 3.2 「补充上一次」复用 `_HeartbeatAccentButton`（或等价），`onPressed` = 与网格点卡相同的 `handleEventGridTap`
- [x] 3.3 关推演时 `onCardTap` 置空，不走加事件补齐
- [x] 3.4 收敛 `_PredictionEventCard` 分支为入参/派生 actions 驱动，避免按空库/缺口分型新 Widget

## 4. 冷热态门闸对齐

- [x] 4.1 保持 `useDemoSkeleton` 仅未登录/未绑定；已绑定空历史走热态完备行
- [x] 4.2 catalog 暂无根且 range pending 时保留加载文案；有根后不得落回忆缺省页

## 5. 验收

- [x] 5.1 手工：空库全量根卡、不弹 Dialog、无「回忆宝宝习惯」缺省页
- [x] 5.2 手工：半记录仍见未记过根；无 lastAt 仅「补充上一次」心跳；点 CTA=点卡加喂养
- [x] 5.3 手工：有 lastAt 无 pred 出现间隔 CTA；写种子后出 countdown
- [x] 5.4 手工：关推演无两种 CTA、点卡不加事件；再开推演后 CTA 恢复
- [x] 5.5 不新建 `**/test/**`

## 6. 「上一次」进编辑 Sheet（续写）

- [x] 6.1 增加从真历史解析 root 最新 `HistoryRecord` 的 helper（排除回忆种子）
- [x] 6.2 热态卡「上一次」文案：有真记录时可点，调用 `showHomeHistoryEditSheet`；挡住整卡加事件；「暂无」不可点
- [x] 6.3 手工：点「上一次」打开与喂养同款编辑 Sheet；改时间保存后卡文案更新
