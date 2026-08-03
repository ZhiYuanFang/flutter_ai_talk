## ADDED Requirements

### Requirement: Compose polish MUST NOT show quota remaining or degraded toast

The compose screen MUST NOT display polish AI monthly remaining quota UI (`AiQuotaRemainingHint` or equivalent). On polish success or failure, the client MUST NOT toast「本月润笔额度已用完，已降速」or equivalent quota-degraded copy. 发布页 **不得** 展示润笔额度剩余；**不得** 因 `quotaDegraded` 弹出额度/降速 toast（客户端先行）。

#### Scenario: 无润笔额度 hint

- **WHEN** 用户打开 compose 且「AI润笔」可见
- **THEN** UI MUST NOT 渲染润笔额度剩余提示

#### Scenario: 润笔成功无降速 toast

- **WHEN** polish API 返回成功（无论 `quotaDegraded` 字段真假）
- **THEN** 客户端 MUST NOT 展示「额度已用完，已降速」类 toast
- **AND** 仍 MUST 按既有规则更新正文为 `polishedText`（成功时）
