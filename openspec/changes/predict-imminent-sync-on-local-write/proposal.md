## Why

当前 `predictImminentPendingSyncProvider` 监听任意 `smartPredictionsProvider` 变化即 `PUT` pending，导致 resume / bootstrap / range force 拉取对齐后的预测重算也会刷后端闹钟；他端 WS 写入本机历史时也会重复同步（对端已推过）。需要把「告知后端」收窄到本机变更喂养记录或喂养间隔之后。

## What Changes

- **BREAKING（客户端行为）**：预测临近 pending 同步不再因「任意预测重算」触发；仅在本机喂养记录变更或喂养间隔（recall 种子）变更、且本地预测已按新输入重算完成后，显式发起 `PUT /device/api/predict/imminent/pending`（方案 B1）。
- 拉取最新数据（`bootstrap`、`ensureLoaded(force)`、resume 包等）触发的预测重算 **MUST NOT** 推 pending。
- 他端历史 WS 合并进本机（`history_ws_home_bridge` → `upsertRecord` / `removeRecord`）**MUST NOT** 推 pending。
- 移除（或停用）对 `smartPredictionsProvider` / session / deviceNo 的盲听自动 sync；保留 single-flight、指纹去重、失败熔断等副作用 HTTP 防护，改为由显式入口调用。
- 同步时机：本机写路径更新 state 后 `ref.read(smartPredictionsProvider)` 再 sync，保证用的是已重算结果；不等待随后的 range 防抖重拉（该重拉视为拉取，不推）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `predict-imminent-client-sync`：将「本地预测更新后必须 sync」收窄为「仅本机喂养记录或喂养间隔变更导致重算完成后 MUST sync」；明确拉取对齐与他端 WS 历史 MUST NOT sync。

## Impact

- `app/lib/providers/predict_imminent_sync_provider.dart`：导出显式 `requestPredictImminentPendingSync`（或等价），去掉盲听。
- 本机写路径挂点：`insertOptimistic` / `replaceRecordImmediate` / 本机删改、以及 `PredictionRecallSeedsNotifier.upsertSeed`（及清种子若影响间隔）；**不得**挂在 WS bridge、bootstrap、range force。
- 与进行中变更 `android-china-push-predict-imminent` 能力同名叠加；本变更以触发条件为准覆盖其「任意预测刷新即 sync」语义。
- HTTP 路径与 body 不变；无新原生依赖。
