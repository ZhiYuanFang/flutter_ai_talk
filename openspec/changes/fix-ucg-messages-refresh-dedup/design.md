## Context

消息 Tab（`UcgMessagesTab`）采用**双轨数据**：

- 私信列表：本地 state（`_loadConversationsFirst` / `_loadConversationsMore`）
- 互动未读：`ucgCommentNotificationsProvider`（Riverpod `FutureProvider.autoDispose`）

未读角标另有第三条链路：

- `syncUcgUnreadFromServer` / `UcgShell._syncShellUnreadBadge` / `HomeScreen.didChangeAppLifecycleState(resumed)`

当前 `_refreshAll()`：

```dart
bumpUcgConversationsRefresh(ref);      // 无 consumer，无效
bumpUcgNotificationsRefresh(ref);        // 触发 provider + Shell listener
await Future.wait([
  _loadConversationsFirst(),
  ref.read(ucgCommentNotificationsProvider.future),
]);
```

`bumpUcgNotificationsRefresh` 会：

1. 使 `ucgCommentNotificationsProvider` 重拉
2. 触发 `UcgShell.ref.listen` → `_syncShellUnreadBadge()` 再拉 conversations + notifications

Web 复现：错误页 → 点浏览器外 → 点回空白（regain focus）→ `HomeScreen.resumed` → `ucgUnreadSyncProvider()`；若 `ensureFreshSession` 刷新 token，`accessToken` listener 再调 `syncUnreadFromWs()`，同接口再打一轮。

约束：遵循 `v2.0.2` 基线；不新增测试文件；不改变 WS 长连与未读 OR 逻辑。

## Goals / Non-Goals

**Goals:**

- 用户点击消息 Tab「重试」或下拉刷新：会话首屏 + 互动通知首屏各 **最多 1 次** HTTP。
- App `resumed`（含 Web 失焦再获焦）：未读 HTTP 校准 **最多 1 轮**（2 个接口各 1 次），不因 token 刷新链式重复。
- 未读角标数值与刷新后 UI 保持一致。

**Non-Goals:**

- 将消息 Tab 完全迁移到 `ucgConversationsProvider`（可后续重构）。
- 修改互动 Inbox 独立分页逻辑。
- 移除 `HomeScreen` KeepAlive 或 PageView 结构。

## Decisions

### 1. 全局 in-flight 合并 `syncUcgUnreadFromServer`

在 `ucg_providers.dart` 提取模块级 `Future<void>? _syncUcgUnreadInFlight`，`syncUcgUnreadFromServer` 入口：

- 若已有 in-flight，返回同一 `Future`（共享结果）
- 完成后清空 in-flight

`UcgShell._syncShellUnreadBadge` 改为调用 `syncUcgUnreadFromServer(ref)`，删除重复的 fetch 实现。

**备选**：各处 debounce 500ms → 仍可能漏掉链式 trigger；in-flight 合并更可靠。

### 2. 精简 `_refreshAll`

```dart
Future<void> _refreshAll() async {
  await Future.wait([
    _loadConversationsFirst(),
    ref.refresh(ucgCommentNotificationsProvider.future),
  ]);
  _syncUnreadBadge();
}
```

- 去掉 `bumpUcgConversationsRefresh`（无 watch 消费者）
- 去掉 `bumpUcgNotificationsRefresh`（避免 Shell 二次 HTTP）
- 未读角标用 Tab 已有数据本地汇总

下拉 `RefreshIndicator` 与错误页「重试」共用此方法。

### 3. Shell 监听保留 bump 语义，HTTP 走去重 sync

`bumpUcgNotificationsRefresh` 仍用于 WS `comment_notification`、Inbox 已读等**需要 invalidate provider** 的场景。

`UcgShell` 对 `ucgNotificationsChangedProvider` 的 listener：

- **不再**调用独立 `_syncShellUnreadBadge` 重复 fetch
- 改为 `unawaited(syncUcgUnreadFromServer(ref))`（合并后仅补角标；provider 已由 bump invalidate）

或：listener 仅 `syncUcgUnreadFromServer`，provider 的 `ref.watch(ucgNotificationsChangedProvider)` 自行 refetch——避免 listener 与 provider 双拉 notifications。

**决策**：Shell listener 改为 **仅** `syncUcgUnreadFromServer`（更新角标）；**不**再单独 invalidate 时双拉。`ucgCommentNotificationsProvider` 已通过 `ref.watch(ucgNotificationsChangedProvider)` 在 bump 时 refetch；listener 只负责角标数字与 conv 侧未读之和，从 sync 结果读取，避免第三次 notifications fetch。

细化：

| 事件 | provider refetch | HTTP sync |
|------|----------------|-----------|
| bump（Inbox 已读等） | 是（watch changed） | 否（角标由 provider 数据 + 本地 conv 汇总） |
| resumed / WS 需校准 | 否（除非 bump） | 是（去重 sync 一次） |
| 消息 Tab `_refreshAll` | refresh provider 一次 | conv 本地 load 一次 |

Shell listener 从「bump → sync 双拉」改为「bump 仅驱动 provider；resumed/WS 走 sync」。

### 4. `accessToken` listener 复用 in-flight sync

`ucgRepositoryProvider` 内 `accessToken` 变化已调 `syncUnreadFromWs()` → `syncUcgUnreadFromServer`。合并 in-flight 后，与 `HomeScreen.resumed` 同一窗口内只执行一轮。

### 5. HomeScreen resume 保持不变，依赖去重

不移动 lifecycle observer 到 `UcgShell`（避免漏掉喂养页-only 场景）。`resumed` 继续 `ucgUnreadSyncProvider()`，由 in-flight 保证不重复。

## Risks / Trade-offs

- **[Risk] in-flight 共享导致短暂失败被多调用方共享** → 可接受；用户可手动重试。
- **[Risk] 去掉 Shell listener 的独立 sync 后，bump 仅 provider 不更新 conv 未读** → 消息 Tab 本地 conv 列表在 bump 时不自动刷新；仅角标依赖 provider unread + 本地 conv，与现网一致；离开聊天页仍会 `_loadConversationsFirst`。
- **[Risk] Web resume 仍发 1 轮 HTTP** → 符合「校准未读」基线，但不再 3 轮。

## Migration Plan

纯客户端逻辑调整，无数据迁移。回滚为还原 `_refreshAll` 与 sync 实现。

## Open Questions

- 是否将 `ucgConversationsProvider` 接入消息 Tab 以单一数据源？本次不做。
