## 1. Resume 刷新

- [x] 1.1 在 `HomeScreen._onAppLifecycleResumed`（session 之后）对已登录用户并行：`homeHistory.bootstrap()` 与 `predictionRangeHistory.ensureLoaded(force: true)`
- [x] 1.2 增加短窗去重（约 3–5s），避免连发 resumed 重复打满；未登录跳过；不改 gave-up WS 规则

## 2. 验收

- [ ] 2.1 手工：仅停留预测页 → 后台 → 前台后，预测卡/进行中无需先刷喂养页即可更新
- [ ] 2.2 手工：未登录 resume 无多余历史 HTTP；短时连切不狂打
