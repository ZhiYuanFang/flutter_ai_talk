## 1. 仓储与 mapper

- [x] 1.1 `feed_repository.dart`：`addHistoryEvent` 改为返回 `Future<String?>`（成功为 `data.id` 字符串）
- [x] 1.2 `remote_feed_repository.dart`：解析 envelope `data.id`；`code != 0` / 异常 Toast 并返回 null
- [x] 1.3 `history_mapper.dart`：新增 `historyRecordFromAddBody`（或等价）由 add body + `pending:<uuid>` 构建 `HistoryRecord`

## 2. Notifier 状态

- [x] 2.1 `home_history_notifier.dart`：`insertOptimistic` / `replaceRecordId(from, to)` / `removeById`
- [x] 2.2 确认 `upsertRecord` 对已存在 id 仅合并字段、不追加重复行

## 3. 主页乐观编排

- [x] 3.1 `home_screen.dart`：重构 `_submitEventAdd` — tap 即 pending 插入 + Toast + `scheduleFly(pendingId)` + 并行 add
- [x] 3.2 add 成功：`replaceRecordId(pending, serverId)`；失败：`removeById`（避免重复 Toast）
- [x] 3.3 `_onEventButtonTap` / 目录 picker 叶子：time / one / number 均走新路径；保留 time 重复校验（含 pending 行）
- [x] 3.4 语音/文字 `sendCommand` 路径：确认未调用乐观插入

## 4. 飞行动画与 WS 去重

- [x] 4.1 `watchLatest`：WS 新增判定排除已存在 id；replace 后短窗口避免二次 `scheduleFly`
- [x] 4.2 乐观路径显式 `scheduleFly`；replace / WS 合并不触发第二次动画
- [x] 4.3 连续快速添加：取消进行中 fly（沿用 `home-event-record-fly-animation` 行为）

## 5. time 型 pending 边缘

- [x] 5.1 计时行 UI：`id.startsWith('pending:')` 时禁用停止计时直至 replace 或移除
- [x] 5.2 replace 完成后恢复现网 `updateHistoryRecord` 停止流程

## 6. 验证

- [x] 6.1 手工：time / one / number、目录叶子；add 成功 id 替换；add 失败回滚；WS 同 id 无重复行无二次动画
- [x] 6.2 手工：语音添加仍仅 WS 插行；pending 期间不可停止
- [x] 6.3 `flutter analyze` + `openspec validate home-event-optimistic-add`
