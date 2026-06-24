## 1. 未读 HTTP 校准去重（`ucg-notifications`）

- [x] 1.1 在 `ucg_providers.dart` 为 `syncUcgUnreadFromServer` 增加 in-flight 合并（共享 `Future`，完成后清空）
- [x] 1.2 将 `UcgShell._syncShellUnreadBadge` 改为调用去重后的 `syncUcgUnreadFromServer`，删除重复 fetch 实现
- [x] 1.3 确认 `ucgRepositoryProvider` 内 `accessToken` / WS 事件触发的 `syncUnreadFromWs` 走同一去重入口

## 2. Shell 监听与 bump 语义（`ucg-notifications` / `ucg-chat-ui`）

- [x] 2.1 调整 `UcgShell` 对 `ucgNotificationsChangedProvider` 的 `ref.listen`：避免 bump 后再独立打一轮与 provider 重复的 notifications HTTP
- [x] 2.2 保留 Inbox / WS 等场景的 `bumpUcgNotificationsRefresh` 以 invalidate provider；角标由 provider + 本地会话未读或去重 sync 汇总

## 3. 消息 Tab 刷新精简（`ucg-chat-ui`）

- [x] 3.1 重写 `UcgMessagesTab._refreshAll`：移除 `bumpUcgConversationsRefresh` 与 `bumpUcgNotificationsRefresh`
- [x] 3.2 使用 `Future.wait([_loadConversationsFirst(), ref.refresh(ucgCommentNotificationsProvider.future)])` 后调用 `_syncUnreadBadge()`
- [x] 3.3 确认下拉刷新与错误页「重试」共用 `_refreshAll`

## 4. 验证

- [ ] 4.1 Web：消息错误页 → 点浏览器外 → 点回空白，Network 中会话/互动首屏接口合计至多 1 轮（2 个请求）
- [ ] 4.2 消息 Tab 点击「重试」，Network 中每个首屏接口至多 1 次
- [ ] 4.3 下拉刷新行为与重试一致，未读角标仍正确
- [x] 4.4 `flutter analyze` 无新增 error（`app/lib/ucg/` 相关文件）
