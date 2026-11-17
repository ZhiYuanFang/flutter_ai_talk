## REMOVED Requirements

### Requirement: Smart prediction page SHALL show a capability status card between next-three-hours and the event list

**Reason**: 档位展示迁至「接下来3小时」标题后缀与全屏三档墙（`predict-capability-tier-wall`）；不再在 3h 与列表间挂独立状态卡。

**Migration**: 删除 `PredictCapabilityStatusCard` 挂载；点档位开墙，不再要求点卡进 Hub。

### Requirement: Capability card copy SHALL reflect entitlement and algorithm readiness

**Reason**: 旧优先级文案（含「基础版待开通」「固定间隔」「VIP 已覆盖预测推送」）由三档后缀 `间隔版|基础版|Pro版` 与墙内底栏取代。

**Migration**: 见 `predict-capability-tier-wall` 标题后缀与底栏态。

### Requirement: Capability card SHALL show syncing copy until entitlement settle is ready

**Reason**: syncing 占位改挂在 3h 标题后缀（或暂不可点），不再依赖独立能力卡。

**Migration**: 见 `predict-capability-tier-wall` syncing 场景。
