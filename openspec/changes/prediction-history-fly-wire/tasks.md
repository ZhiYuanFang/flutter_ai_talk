## 1. 预测页承接飞入

- [x] 1.1 确认预测飞入仅由 `ucg_home_shell._KeepAlivePredictionPage` 承接（勿在 `SmartPredictionScreen` 再挂 Overlay）
- [x] 1.2 壳层 Overlay：`keyFor` 锚点 + `disableAnimations` 时 clear session；去掉预测页内重复宿主

## 2. 校验

- [x] 2.1 `openspec validate prediction-history-fly-wire --strict`
- [ ] 2.2 手工：预测页加/改仅**一次**飞入；喂养仍有；UCG 不飞
