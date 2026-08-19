## Why

用户在智能预测主页（默认着陆页）通过「绑定已有宝宝」成功后，客户端仅更新本地 `deviceNo` 并重连历史 WebSocket，**未可靠触发 HTTP 拉取该宝宝的历史列表**。`homeHistoryProvider` 的 `bootstrap`/`refreshFromRemote` 监听写在 `HomeScreen` 内，而 `PageView` 默认展示预测页、喂养页可能从未挂载，导致绑定后列表长期为空或仍显示旧宝宝数据。预测 as home hub 架构下该问题已可稳定复现。

## What Changes

- 在 `homeHistoryProvider` 层注册 `deviceNoNotifierProvider` 监听：当 `deviceNo` **实质变更**（含空→非空、A→B）且用户已登录时，MUST 触发 `bootstrap()`（必要时 bump epoch、清旧内存/避免 A 残留）。
- 扩展 `predictionRangeHistoryProvider` 的 `deviceNo` 监听：任意 `prevDn != nextDn`（非空）时 `ensureLoaded(force: true)`，覆盖换绑已有宝宝场景。
- `baby_bind_screen` 绑定/创建成功后保留现有 token 对齐与 WS 重连，并作为双保险显式调度历史 bootstrap（不阻塞 pop）。
- 不改动 Splash 冷启动路径、不新增测试文件；副作用 HTTP 仍须 single-flight（复用 notifier 既有 `_refreshFuture` / `_inFlight`）。

## Capabilities

### New Capabilities

（无独立新 capability。）

### Modified Capabilities

- `device-identity`：补充「宝宝绑定/切换成功后 MUST 触发 HTTP 历史 bootstrap」约束，与现有 token/WS 对齐 Requirement 配套。
- `home-history-disk-cache`：补充「deviceNo 变更 MUST 在 Provider 层触发 stale-while-revalidate，不得依赖 HomeScreen 挂载」。

## Impact

- `app/lib/providers/home_history_notifier.dart`：`homeHistoryProvider` 注册 `deviceNo` listen；可选 `clearForDeviceChange()`。
- `app/lib/providers/prediction_range_history_provider.dart`：扩展 deviceNo 变更条件。
- `app/lib/ui/baby_bind_screen.dart`：绑定/创建成功后显式 `unawaited` bootstrap。
- `app/lib/ui/home_screen.dart`：可保留现有 listen 作为冗余，或收敛为仅 Provider 层（实现阶段择一，避免双跑需 single-flight）。
- 无 Android 原生 / 新依赖 / WebSocket 架构变更。
