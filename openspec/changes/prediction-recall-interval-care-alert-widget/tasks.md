## 1. 昨日历史门闸与留意拉取

- [x] 1.1 新增 `rangeHasShanghaiYesterdayOccurrence`（`occurrenceInstant` + Shanghai 日历日）及共享 helper 文件或置于 `prediction_care_alert.dart` / range 模块
- [x] 1.2 更新 `predictionCareAlertFetchAllowedProvider` 与 `predictionCareAlertProvider` 内 `canFetch` 判定为昨日门闸
- [x] 1.3 确认 `ucg_home_shell` 三门闸 listen（进入页 / gate false→true / 历史变非空）仍触发 ensure；更新 skip 日志字段
- [x] 1.4 门闸 false 时 `ensureLoaded` 清空 state 且不标 failed（对照 spec Scenario）

## 2. 小组件 tip 从留意派生

- [x] 2.1 实现 `deriveWidgetTipTextFromCareAlert(List<CareAlertEventItem>)`（仅非空 `summaryLine`，`\n\n` 拼接，不回退 detailLines）
- [x] 2.2 重构 `resolveWidgetTip`：移除 `kWidgetTipFailDayKey` 读写；空结果不 write fail；保留 day/text/full prefs 与 trim 规则
- [x] 2.3 `syncHomeWidgetFromRef`：gate 通过且留意 ready 时 read state 派生 tip；gate 通过未 ready 时 ensure 后重读；未 ready 复用 prefs 快照不清空；ready 且空则清除 tip
- [x] 2.4 移除 `RemoteFeedRepository.fetchWidgetFeedingTip` 内 `watch(predictionCareAlertProvider)`；改为 sync 层 read 或删除 chat 死代码
- [x] 2.5 留意 ensure 成功、`ignoreSuggestion` 后 `scheduleHomeWidgetSync`（若尚未串联则补）
- [x] 2.6 一次性迁移：启动时 `remove(kWidgetTipFailDayKey)` 或于 `clearWidgetTipCache` 清理（可选注释）

## 3. 预测卡 per-card 仅间隔回忆

- [x] 3.1 `_PredictionEventCard`：条件展示全宽心跳 FilledButton CTA（enabled && pred==null && lastAt!=null && onToggle!=null）
- [x] 3.2 间隔 Sheet 标题 `{EventLogo}{eventName}·大概多久一次`；复用 `showGlassSingleWheelPickerSheet`（与 recall onboarding 同项表）
- [x] 3.3 确认后 `PredictionRecallSeed` upsert（lastAt 来自 row，synthesizeOccurrenceAts）；toast 可选
- [x] 3.4 验证与空库 recall Dialog 不冲突（`predictionRecallEmptyHistoryEligible` 时会话优先）

## 4. 验证与文档

- [ ] 4.1 手工：仅今日记录 → 不拉留意、widget 无 tip；有昨日记录 → 留意与 tip 正常
- [ ] 4.2 手工：热态单事件补间隔 → 卡片出现 countdown；忽略留意 → widget tip 更新
- [x] 4.3 确认无新增裸 `debugPrint`；留意/tip 路径日志用 `AppDebugLog.careAlert` / `AppDebugLog.homeWidget`
