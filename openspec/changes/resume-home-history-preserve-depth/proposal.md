## Why

已登录 App 久置后台再回前台时，主壳 resume bundle 会走 `homeHistory.bootstrap()` → `refreshFromRemote()`，把内存（并常落盘）收成 **仅第 1 页**，再 force 预测 range。用户此前 loadMore 得到的更深历史从预测并集消失，预测卡上窗外事件的「上一次」/可推演态像被「缓存弄丢」；杀进程冷启动若仍靠 tip 或其它路径才恢复，体验不一致。需要在 **仍拉最新一页** 的前提下，**resume 不得砍掉已加载更深页**。

## What Changes

- Resume / bootstrap 触发的 home 远端刷新：拉取 page 1 后 **按 id 合并进现有列表**，保留已加载的更旧页；**不得**将 `highestPageLoaded` 压成 1 并整表替换为仅 page 1。
- 落盘：该路径 MUST 持久化「page1 ∪ 仍保留的更深页」快照，**不得**写成只有 page 1 的瘦快照覆盖更深缓存。
- 用户显式手势刷新（喂养列表顶部非 loadMore 下拉、底部上拉）：**仍可**整表替换为最新一页（既有「刷新最新一页」语义保留）。
- 预测 range 的 resume `ensureLoaded(force: true)` **保留**；本变更不改 tip 算法，但 resume 不再因砍窗误伤并集深度。
- 无新 HTTP 端点；无 **BREAKING** API。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-history-resume-refresh`：明确 resume 的 home 刷新 MUST 保留已加载历史深度（合并最新一页，非 page1 整表替换）。
- `home-history-pagination`：区分「显式手势刷新最新一页（可整表替换）」与「resume/bootstrap 合并最新一页且保留更深页」。
- `home-history-disk-cache`：resume 合并路径落盘 MUST 保留更深页，不得用 page1-only 快照覆盖。

## Impact

- `app/lib/providers/home_history_notifier.dart`：`refreshFromRemote` / bootstrap 分模式或参数。
- `app/lib/data/history_mapper.dart`（或邻近）：page1 upsert + 保留更深页的纯函数。
- `app/lib/ucg/ui/ucg_home_shell.dart`：resume 仍调 bootstrap，行为随 notifier 变更。
- 预测并集（`predictionRealHistoryProvider`）间接受益；无 Go / R8 变更。
