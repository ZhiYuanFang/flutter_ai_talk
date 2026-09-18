## Context

`predictImminentPendingSyncProvider` 当前 `ref.listen(smartPredictionsProvider)`（以及 session / deviceNo / 首次订阅）在任意预测列表变化时 `PUT /device/api/predict/imminent/pending`。预测列表由 `homeHistory ∪ rangeHistory` + recall 间隔驱动，因此 resume 拉数、`scheduleInvalidation` 后的 range force、他端 WS upsert 都会间接触发 pending 同步。

产品要求（方案 **B1**）：仅本机变更喂养记录或喂养间隔时，在本地预测按新输入重算完成后推后端；拉取对齐与他端 WS 不推（对端已推）。

约束：副作用 HTTP 须保留 single-flight、指纹幂等、失败熔断；日志走 `AppDebugLog.predictImminent`；不改 Go API。

## Goals / Non-Goals

**Goals:**

- 显式入口：本机写历史 / 写间隔后 `read(smartPredictionsProvider)` → `syncPending`。
- 拉取路径与他端 WS 历史桥 **不** 调用该入口。
- 去掉对 `smartPredictionsProvider`（及因此产生的盲同步）的 listen。

**Non-Goals:**

- 不改 pending HTTP 契约、不清空语义、不改推送 register。
- 不等待 range 防抖重拉后再推（该重拉视为拉取）。
- 不解决多端并发写时服务端 last-writer 冲突以外的协调（本机不推他端已写即可）。
- 不在本次改登录后「冷启动补推」策略（见 Open Questions）。

## Decisions

### D1：B1 显式 sync，而非拉取期 suppress（A）或 armed-listen（B2）

- **选择**：导出 `requestPredictImminentPendingSync(Ref)`（名可微调），由本机写路径调用；provider 可仅保留仓库 Provider + 激活壳层无副作用，或薄包装不再 listen 预测。
- **理由**：触发语义与调用栈一致；避免 suppress 窗口与写入交错；避免 armed 与 range 二次通知竞态。
- **替代**：A 改动小但「默认仍听预测」易漏 suppress；B2 仍依赖 listen，挂点不如 B1 清晰。

### D2：算完边界 = 同步 Riverpod 重算，非 range HTTP

本机 `insertOptimistic` / `replaceRecordImmediate` / 本机删改 / `upsertSeed` 更新 state 后立刻：

```
ref.read(smartPredictionsProvider);
→ requestPredictImminentPendingSync(...)
```

预测为同步纯函数，read 即算完。随后 `scheduleInvalidation` → range force **不得**再 sync。

### D3：挂点按入口区分，不按 `upsertRecord` 一律推

| 入口 | sync？ |
|------|--------|
| `insertOptimistic`、`replaceRecordImmediate`、本机编辑删除停计时 | 是 |
| `PredictionRecallSeedsNotifier.upsertSeed`（及会改变有效间隔的 clear） | 是 |
| `history_ws_home_bridge` → `upsertRecord` / `removeRecord` | 否 |
| `bootstrap` / `ensureLoaded(force)` / resume 包 | 否 |
| `setItems` 仅因 WS/`bootstrap` | 否 |

本机加餐若走 `upsertRecord`，须在 **UI/动作层**（如 `event_add_actions`）写完后显式 request，或给 notifier 增加 `syncImminent: true` 参数且默认 false——优先显式 request，避免 WS 共用方法误推。

### D4：保留防护，去掉盲听触发源

保留 `_predictImminentSyncInFlight`、指纹、失败计数与 cooldown；去掉 listen 预测 / session / deviceNo 自动 sync。主壳若曾 `watch(predictImminentPendingSyncProvider)` 仅为激活 listen，改为不再依赖该副作用 watch（或 provider 变为 no-op 文档化）。

## Risks / Trade-offs

- [Risk] 本机写漏挂 request → 服务端闹钟过期  
  → Mitigation：tasks 列全挂点；对照 `event_add_actions`、edit sheet、active timing stop、recall upsert。

- [Risk] 仅 home 更新、range 尚未重拉时 nextAt 略偏  
  → Mitigation：接受；新产品不要求等 range；新记录已在 home，对临近事件通常足够。

- [Risk] 登录换机后直至本机再写才 PUT，旧 pending 短暂残留  
  → Mitigation：列为 Open Question；若需要可另加「激活会话一次」补推（非本变更默认）。

- [Risk] 与 `android-china-push-predict-imminent` 规格「任意刷新即 sync」冲突  
  → Mitigation：本变更 MODIFIED 同能力规格；实现以本变更为准。

## Migration Plan

- 纯客户端行为收窄；无数据迁移。
- 回滚：恢复 listen `smartPredictionsProvider` 即可。

## Open Questions

- 登录成功或换绑宝宝后，是否需要一次补推 pending？（默认：**否**，等本机下次写。）
