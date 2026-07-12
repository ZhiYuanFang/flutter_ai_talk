# Implementation Tasks — decouple-history-updates-from-ws

1. 提案与设计
   - [x] 创建 `openspec/changes/decouple-history-updates-from-ws/proposal.md`
   - [x] 创建 `openspec/changes/decouple-history-updates-from-ws/design.md`

2. 代码实现（最小改动，HTTP 优先）
   - [x] 修改 `app/lib/ui/home_screen.dart` 中 `_stopActiveTimer`：当 `feed.isHistoryWebSocketReady == false` 时改为直接调用 `await feed.updateHistoryRecord(...)`，并根据返回值决定保留或回退 UI。
   - 额外规则：若 HTTP 请求失败（business 或 transport），需立即删除对应的 pending 记录并向用户展示失败提示（不保留 pending）。
   - [x] 扫描并修改仓库中其他调用 `enqueueHistoryUpdateOutbox` 的位置（如 `home_history_edit_sheet.dart`），把更新类操作改为 HTTP 优先，失败时回退并提示；并在使用 `fallbackRecord` 的场景保证在 HTTP 失败时“老实承认”失败（不要把失败当作成功）。
   - [ ] 确保 `history_outbox_flusher` 在处理持久化 outbox 时，flush 成功应被视作 HTTP 成功：在 UI 层执行相应的确认（如 `replaceRecordId` / `replaceRecordImmediate`）并标记为已确认；不要触发针对 optimistic 行的回滚逻辑。

3. 测试与验证
   - [ ] 添加单元测试覆盖 `_stopActiveTimer` 的主要路径（pending / HTTP success / HTTP failure）。
   - [ ] 手动验收：在离线/弱网环境下执行停止计时/编辑操作，验证 UI 回退与提示；验证语音路径仍需要 WS。

4. 文档与变更记录
   - [ ] 在 `openspec` 中标注变更合规性（已创建 proposal/design/tasks）。
   - [ ] 更新 `app/README.md` 或相关开发文档（如有）说明更新策略与回退行为。

5. 观察与后续（可选）
   - [ ] 在灰度发布后观察失败率与用户反馈，评估是否需要删除或改造 `history_outbox_flusher` 的 WS 触发条件。
