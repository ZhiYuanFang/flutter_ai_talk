## REMOVED Requirements

### Requirement: Debug CLEAR_PREDICT_ALGO_REMIND SHALL clear reminded cache only when enabled

**Reason**: 算法就绪提醒产品路径已废弃；不再维护 reminded store，也不再需要 debug define 清缓存。

**Migration**: 删除 `Env.clearPredictAlgoRemind` / `CLEAR_PREDICT_ALGO_REMIND`、`PredictAlgoReadyRemindStore` 及 `main`/`wipe` 中的清除调用；settle 相位与 catalog ensure 行为不变。
