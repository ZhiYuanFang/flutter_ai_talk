## 1. Ensure 触发

- [x] 1.1 `UcgHomeShell`：listen `predictionCareAlertFetchAllowedProvider` 边沿 false→true 且在预测页时调用 ensure（可保留/收敛 range wasEmpty listen）
- [x] 1.2 `_ensureCareAlertOnPredictionVisible`：门闸未放行时 `AppDebugLog.careAlert` 跳过摘要；放行后再 ensure +（可选）widget sync
- [x] 1.3 `ensureLoaded`：未登录 / 无 deviceNo 早退同样打 CareAlert 日志

## 2. 假加载 UI

- [x] 2.1 `_CareAlertPanel`：路线 1 回滚 tip-align 后恢复 `loading || !ready` →「加载中…」；失败与空列表仍分流（接口异常 / 真棒进陪伴）
- [x] 2.2 tip-align VIP 空态族已回滚；本变更只保留 ensure 门闸与 CareAlert 跳过日志

## 3. 校验

- [x] 3.1 `openspec validate care-alert-ensure-gate-fix --strict` 通过
- [ ] 3.2 手工冷启动：range 非空后出现 `[CareAlert]` 与/或 `care-alert/daily`；不得永久仅「加载中…」
