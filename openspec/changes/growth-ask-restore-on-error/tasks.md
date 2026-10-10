## 1. Provider

- [x] 1.1 `answer` 开流不清 `question`；失败/异常结束恢复 `asking` + 原题
- [x] 1.2 `start`/`restart` 失败路径保持清题
- [x] 1.3 `ensureLatest`：先保 asking/streaming；门闸对齐 `canAccessFeatureDetail`；不可进时不强行 idle 冲题

## 2. 验收

- [x] 2.1 对照 spec：提交失败恢复追问；再进页保题（含试用）
