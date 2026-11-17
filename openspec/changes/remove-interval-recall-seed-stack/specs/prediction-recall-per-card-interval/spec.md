## REMOVED Requirements

### Requirement: Per-card interval recall SHALL apply when hot state lacks prediction but has lastAt

**Reason**: 产品硬删「补充大概多久一次」与回忆种子栈；无亲和 nextAt 改走亲和进度。  
**Migration**: 见 `retire-interval-recall-seed-stack`；卡面删除间隔 CTA；勿再 upsert 种子。

### Requirement: Appointment cards MUST supplement next trigger time instead of interval

**Reason**: 需求正文仍绑定「非预约保持间隔补充」；预约「补充下次」改由其它能力/本变更 retire 场景保留，本条整体移除以免复活间隔 CTA。  
**Migration**: 预约「补充下次」行为继续由 appointment / smart-prediction 既有预约 sheet 路径约束；非预约间隔 CTA 禁止见 `retire-interval-recall-seed-stack`。

## ADDED Requirements

### Requirement: Appointment cards MUST keep next-trigger supplement without interval recall

For appointment prediction cards, the client MUST present next-trigger-time supplement/edit via the dedicated next-appointment sheet and MUST NOT use per-card interval recall. Non-appointment cards MUST NOT present interval-recall CTAs. 预约卡 MUST 以专用「补充下次」sheet 为主路径且 MUST NOT 走间隔回忆；非预约卡 MUST NOT 展示间隔回忆 CTA。

#### Scenario: Appointment card opens next-time editor

- **WHEN** 用户在预约预测卡上发起「补充下次」类操作
- **THEN** 客户端 MUST 进入专用下一次预约 sheet
- **AND** MUST NOT 打开「大概多久一次」间隔 picker

#### Scenario: Non-appointment has no interval CTA

- **WHEN** 非预约热态卡无亲和预测且有真 lastAt
- **THEN** 客户端 MUST NOT 展示「补充大概多久一次」
