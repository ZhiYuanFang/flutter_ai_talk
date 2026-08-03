## 1. 按钮同步成功后入列

- [x] 1.1 改写 `_submitEventAdd`：去掉 pending；先 HTTP add，成功后以 serverId 入列（不飞入）
- [x] 1.2 增加 add in-flight 标志，禁用事件网格 / number 确认等再次添加入口；失败 Toast 且不入列
- [x] 1.3 成功后 `_triggerTipGeneration`；HTTP 登记 `_awaitingWsFlyIds`，飞入仅由 WS（isNew 或 awaiting）
- [x] 1.4 清理误导性「1 小时去抖」等 tip 注释；确认按钮路径无 `_ensureHistoryWsForSend`
- [x] 1.5 Home bootstrap 跨 await 使用 `ProviderContainer`，避免 dispose 后 WidgetRef.read

## 2. 删除 outbox

- [x] 2.1 删除 `history_outbox_store.dart`、`history_outbox_flusher.dart` 及所有引用
- [x] 2.2 从 `FeedRepository` / `RemoteFeedRepository` / `home_history_notifier` 移除 enqueue/flush/clear outbox
- [x] 2.3 移除 `AppDebugLog.historyOutbox` 并三联更新 `logcat_api_http.ps1`、`app/README.md`
- [x] 2.4 停表等路径确认仅即时 HTTP，失败 Toast，无 outbox 回退

## 3. History WS 双模式

- [x] 3.1 语音按住/发送保留 `_ensureHistoryWsForSend`；切换语音不增加 WS 门闩
- [x] 3.2 `showWsBanner` 增加「当前为语音模式」条件（按钮 / Web 文字模式不显示 gaveUp 横幅）

## 4. 小贴士 Markdown

- [x] 4.1 确认/修复 `HomeTipPanel` done 态经 `ClinicAnswerBody` 渲染 `##` 等标题（布局约束不导致字面量回退）

## 5. 验收

- [ ] 5.1 手工：本机添加 → HTTP 后列表+tip、无飞入；WS 到后飞入；失败不入列；添加中按钮禁用
- [ ] 5.2 手工：按钮模式 gaveUp 无横幅仍可添加；语音模式 gaveUp 有横幅；语音未就绪按住/发送被拦，切换不拦
- [ ] 5.3 手工：tip done 含 `##` 呈标题样式；未改 `app/android/**` 则无需 release APK
