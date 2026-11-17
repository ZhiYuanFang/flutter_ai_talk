## Context

免费亲和与开通中心退休后，产品面已迁到「接下来3小时」两档墙与墙内试用/付费。代码里仍留下三层死物：

1. **算法就绪空转**：`maybeShowPredictAlgoReadyOnboarding` 直接 return；Host / store / `CLEAR_PREDICT_ALGO_REMIND` / `silentAffinityReady` 只服务这条空路径。
2. **孤儿 stub**：邀请码对话框、额度 hint、无站外引用的 entitlement helper、未 report 的用量事件。
3. **redirect-only 路由**：`app_router` 中六条退休 path 仅 `→ /home`，与「不得再维护退休产品面」目标冲突。

`/pangbao` 仍带切预测页副作用，不在清场范围。

## Goals / Non-Goals

**Goals:**

- 删除上述空转与孤儿，降低维护面。
- 退休 path **不再注册** GoRoute；不得再渲染 Hub / VIP 购页 / AI 分析 / companion / invite-howto。
- 小智购买说明继续可用 `inviteGroupQrUrl` 解析。
- 试用成功确认保留，文案不再提开通中心。
- settle 相位与墙内 Pro 付费/试用 **行为不变**。

**Non-Goals:**

- 不改 Pro 墙、catalog、支付、trial/start 契约。
- 不重写 v2.2.1 大基线全文（靠本 change delta；收版时再合并）。
- 不做全局 dead-code 自动化扫描 / 依赖裁剪。
- 不删 `/pangbao`、Live Activity `pangbao://` 顶层 redirect。
- 不追求可测的 APK 体积收益作为验收标准。

## Decisions

### D1：一个 change 覆盖 A+B+C

- **选择**：同 change 清空转 + 孤儿 + 删 redirect 路由。
- **备选**：分两次（先 A/B 再 C）——否决：同属维护清场，拆开会重复分析与归档。

### D2：C 硬删路由，不保留 stub 表

- **选择**：删除六条 redirect-only `GoRoute`；未匹配走既有 `errorBuilder`。
- **备选 A**：保留 redirect（当前状态）——否决：继续暗示「这些 path 仍是一等公民」。
- **备选 B**：顶层 `kRetiredPaths` 映射 `/home`——否决：仍是兼容表，维护收益有限。
- **体验**：`errorBuilder` 增加明确「回主页」操作（按钮或等价），避免旧书签卡在纯错误文案。

### D3：算法就绪整栈删除

- **选择**：删 store、define、Host、no-op onboarding、`silentAffinityReady` 字段与 `rootAffinityReadyWithoutSeed`。
- **保留**：`showPredictBasicTrialSuccessDialog`；`predictEntitlementSettlePhaseProvider` / WarmupHost。
- **理由**：弹窗路径已产品废弃；留 define 只会让人误以为还能再弹。

### D4：howto 抽 QR helper，删页

- **选择**：将 `resolveInviteGroupQrUrl` 挪到薄模块（如 `invite_group_qr_url.dart` 或并入既有 `feature_pay_helpers.dart`）；删除 `InviteCodeHowtoScreen` 与 `invite_code_dialog.dart`。
- **备选**：整文件保留 howto 仅 export helper——否决：文件名误导。

### D5：entitlement helper 按引用删

- **删除**（当前无站外引用）：`isPredictDisplayEntitled`、`ensurePredictDisplayEntitled`、`predictDisplayEntitledProvider`、`canAccessFeatureDetail`、`shouldShowFreeTrialCta`、`shouldShowPredictionAccumulationCtas`、`displayUnlockMethod`、`isFeatureEffectivelyUnlocked`。
- **保留**：`predictCapabilityItems`、`predictEntitlementSettlePhaseProvider`、`isCatalogFeatureTimeValid`（仍被档位/墙使用）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 旧推送/书签进退休 path 看到「路由错误」 | errorBuilder 提供回主页；原生侧已无这些 path |
| 误删仍被墙/试用引用的符号 | apply 前 `rg` 引用；改后 `flutter analyze` |
| wipe 仍调已删 store | 同步改 `wipe_account_local_state` |
| README / logcat / 终端仍带 CLEAR define | 文档与脚本三联清；开发者去掉 run 参数 |
| 与未归档 settle-gate / retire-hub change 文案冲突 | 本 change delta 显式 REMOVED/MODIFIED，以后者为准 |

## Migration Plan

1. 合入纯删代码；无需服务端迁移。
2. 本地 SharedPreferences 中 algo-ready reminded key 可残留，无读取方可忽略（不强制迁移清）。
3. 回滚：git revert；无 DB schema。

## Open Questions

- （无）C 的错误页是否自动 `go('/home')` 已定为「提供回主页出口即可，不必自动跳」。
