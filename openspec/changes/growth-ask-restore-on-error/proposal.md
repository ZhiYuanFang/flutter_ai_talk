## Why

成长轨迹在追问阶段若 turn/提交失败，客户端会 `clearQuestion` 并落到 idle/ready；`/latest` 又不返回未答问题。用户退出再进后看不到之前的追问，只能重新预测。

## What Changes

- `answer` 开流时保留当前 `question`，仅在收到新 `question` / `result` 时替换或清空。
- turn 失败（SSE error / 业务异常 / catch / 流异常结束仍 streaming）：若为本轮 `answer` 且仍有可恢复追问与 sessionId，**恢复 `asking` + 原题**；`start`/`restart` 失败行为不变。
- `ensureLatest`：优先保留 asking/streaming；门闸与进页一致（含试用）；禁止因 `!isEffectivelyUnlocked` 把追问打成 idle。
- Spec 增量：失败恢复追问；再进页保题。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `growth-trajectory-predict`：追问提交失败后 MUST 恢复原问题展示，不得因错误清空导致再进页无题。

## Impact

- 代码：`growth_trajectory_provider.dart`
- 无服务端变更；pending question 仍不依赖 `/latest`
