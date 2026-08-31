## 1. Resume 刷新（首版 · 已落地在 HomeScreen）

- [x] 1.1 （历史）在 `HomeScreen` resume 并行 bootstrap + range force
- [x] 1.2 （历史）短窗去重；未登录跳过

## 2. 迁到主壳 + 加宽 bundle

- [x] 2.1 在 `UcgHomeShell` resume：`ensureFreshSession` 后启动 HTTP bundle（history bootstrap、range force、care full ensure、ucgUnreadSync）；与 WS heal 解耦，ready 早退不得跳过 HTTP
- [x] 2.2 短窗（约 4s）+ single-flight 覆盖整个 HTTP bundle；未登录跳过
- [x] 2.3 从 `HomeScreen` 移除 resume 历史刷新与 `ucgUnreadSync`，避免双打

## 3. 验收

- [ ] 3.1 仅预测页（尽量不进喂养）→ 后台 → 前台：预测卡/进行中更新
- [ ] 3.2 值得留意未合格进度或刚合格内容在 resume 后更新；未读 count 可更新
- [ ] 3.3 未登录 resume 无多余 bundle HTTP；短时连切不狂打；WS ready 时 HTTP 仍执行
- [x] 3.4 `openspec validate prediction-history-refresh-on-resume --strict`
