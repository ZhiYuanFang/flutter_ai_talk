## Context

`_runTurn` 在开流时一律 `clearQuestion`，失败路径再清一次并落到 idle/ready。`ensureLatest` 只拉结果 Markdown。追问仅存在于内存。

## Goals / Non-Goals

**Goals:**

- `answer` 失败后恢复原 `question` + `asking`，退出再进仍可见（provider 未 clear）。
- `start`/`restart` 失败仍清题并 idle/ready。

**Non-Goals:**

- `/latest` 持久化 pending question（后续可选）。
- 改 SSE/Python 协议。

## Decisions

### D1：answer 开流不清题

- `clearQuestion: action != 'answer'`；思考期 UI 仍走 streaming，但 state 保留题。
- 成功新题 / result 时照常覆盖或清空。

### D2：失败统一 `applyTurnFailure`

- 可恢复条件：`action==answer` && `savedQuestion!=null` && `savedSessionId` 非空。
- 满足则 `asking` + 写回题与 sessionId + errorMessage。
- 流正常结束仍停在 streaming 时，answer 同样恢复（防无 error 帧的空结束）。

### D3：ensureLatest 再进保题

- **先**判断 `asking`/`streaming` → return（含 `force: true`）。
- 门闸改 `canAccessFeatureDetail`（与页面一致，含试用）；不可进时只标 `latestLoaded`，**不**强行 `phase=idle`。
- `fetchLatest` 返回后若已进入 asking/streaming，放弃写回，防竞态清题。

## Risks / Trade-offs

- **[Risk] 服务端会话已失效** → 用户再提交会再报错；可接受，优于丢题。
- **[Trade-off] 进程被杀** → 内存仍丢；需服务端 pending 才彻底解决。

## Open Questions

- （无）
