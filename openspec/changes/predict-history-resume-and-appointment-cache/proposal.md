## Why

统一历史池落地后，主壳 resume 仍 force 近 7 日 filter，与冷启叠加易重复拉满窗；预测卡「上一次」优先 `latest-by-event`，resume 合并历史后展示可能被旧 API 缓存挡住；下拉刷新仍打满 7 日 + latest-by-event，过宽；预约 next/last 仅有进程内存、`ensure` 已知则不再请求，冷启空白且无「先缓存后静默刷新」。需一次收束：冷启 7 日、resume 滚动 24h、上一次跟历史池、下拉收窄、预约持久缓存。

## What Changes

- **Resume 历史**：已登录主壳 resume HTTP 对喂养统一池 MUST 请求 **滚动 24 小时**（`now−24h → now`）`filter` 并 id 合并，保留窗外更旧本地行；MUST NOT 因 resume 再 force 全量近 7 日。冷启 / 显式种子仍为近 7 日。磁盘/内存缓存 MUST 可先上屏。
- **Resume 预约**：同一 resume bundle MUST **并行静默刷新**预约 next 与 last（不依赖预测页 mount）；失败 MUST NOT toast、MUST 保留上次缓存。
- **冷启去重（顺带）**：Gateway 与喂养页二次 `ColdStartBackgroundSync` MUST NOT 在短窗内无合并地连打两次 7 日种子（单飞或「刚成功则跳过」）。
- **非预约「上一次」**：卡面展示主源 MUST 为统一历史池内同桶最新真发生（及 remark）；MUST NOT 再以 `latest-by-event` 为展示主源。tip 仅作弱回退。
- **预约 next/last**：展示 MUST **只认**预约本地缓存（内存+盘）；进预测 / 下拉 / **resume** MUST 先展示缓存再静默 API 写回。预约「上一次」MUST NOT 以统一历史池为展示主源。预取 MUST 在 `deviceNo` 可用后才完成网络刷新（避免空 dn 早退后不再重跑）。
- **预测页下拉**：MUST 收窄为滚动 24h 历史合并 + 预约 next/last 静默刷新。MUST NOT force 7 日 + 必打 latest-by-event。

## Capabilities

### New Capabilities

- `appointment-local-cache-silent-refresh`：预约 next/last 磁盘缓存、先展示后静默刷新；触发面含进预测/下拉/resume；wipe 清理；deviceNo 就绪后才网刷。
- `predict-card-last-from-history-pool`：非预约卡上一次以统一历史池为主源（取代 latest-by-event）。

### Modified Capabilities

- `prediction-history-resume-refresh`：resume = 滚动 24h + unread + 预约 next/last 静默；冷启短窗不去重连打 7 日。
- `smart-prediction-page`：下拉 = 24h + 预约 next/last；去掉必打 7 日 / latest-by-event。
- `appointment-event-client`：预约「上一次」展示只认预约 last 缓存；静默不限窗 filter 写回。
- `predict-merge-dimension`：非预约上一次主源从 latest-by-event 改为统一池同桶。

## Impact

- **Flutter**：`ucg_home_shell` resume bundle、`home_history_notifier`、`ColdStartBackgroundSync`、`smart_prediction_screen`、`smart_prediction_rows`（预约 last 跟缓存）、`appointment_*` prefetch watch deviceNo、`wipe_account_local_state`。
- **无 Go API 变更**。
- **风险**：仅 24h resume 扫不到更旧服务端删除；预约与非预约上一次双路径，避免混用池盖预约缓存。
