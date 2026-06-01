## 1. 候选检测与调度

- [x] 1.1 在 `HomeScreen` 实现 `_otherActiveTimingCandidates({required String excludeRecordId})`：从 `homeHistoryProvider` 过滤 `isActiveTimingRecord`、排除 exclude id 与 `isPendingHistoryId`
- [x] 1.2 实现 `_scheduleActiveTimingReminderAfterAdd({required String excludeRecordId})`：无候选则 return；对话框已打开则跳过；有 fly 则挂到 `_onFlyOverlayComplete`，否则 post-frame 调用
- [x] 1.3 在 `_submitEventAdd` 成功（`serverId != null` + `replaceRecordId`）后调用调度，`excludeRecordId = serverId`
- [x] 1.4 在 WS `upsertRecord` 且 `isNew`、非按钮 optimistic 重复路径时调用调度，`excludeRecordId = r.id`

## 2. 居中玻璃风提醒对话框

- [x] 2.1 新增 `home_active_timing_reminder_dialog.dart`：`showHomeActiveTimingReminderDialog` 使用 `showDialog` + 透明 barrier + 居中 `HistoryEditGlassPanel`
- [x] 2.2 实现标题「还有计时未结束」、说明文案、底栏 `TextButton('暂不')` + pill `FilledButton`（单条时「结束计时」，多条时「结束所选」）
- [x] 2.3 列表行展示事件名、accent 色点/`EventLogo`（catalog 可解析时）、实时已计时长（复用 `formatActiveTimingElapsed` 或同等逻辑）
- [x] 2.4 对话框内 `Timer.periodic(1s)` 刷新已计时长，dispose 时取消

## 3. 多选与部分结束

- [x] 3.1 多条候选时每行 Checkbox，默认全选；单条时隐藏 Checkbox
- [x] 3.2 未勾选任何一条时禁用主按钮；确认后对选中记录顺序调用传入的 `onStop`（复用 `_stopActiveTimer`）
- [x] 3.3 部分 stop 失败时 Toast，已成功项关闭或更新列表；全部成功后 `Navigator.pop`

## 4. 集成与手工验证

- [x] 4.1 确认同 eventId time 按钮 Toast 路径不受影响、不弹本对话框
- [x] 4.2 手工验证：按钮 one/time/number 新增后 0/1/N 条其它计时；语音/文字新增；部分勾选 stop；暂不 dismiss；深浅色 shell；fly 动画结束后再弹窗

## 5. 结束成功后关闭对话框

- [x] 5.1 所选全部停止成功时 `Navigator.pop`；`onStop` 与 `isRecordActivelyTiming` 对账（含 WS 已结束但 API 返回 false）
- [x] 5.2 `_stopActiveTimer`：本地已非进行中时视为成功
- [x] 5.3 停止成功后重置 `_stopping`，关闭按钮与自动关窗均可用（不再依赖 `canPop` / 拦截 `_dismiss`）
