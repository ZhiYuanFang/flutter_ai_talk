## ADDED Requirements

### Requirement: Algo-ready dialog SHALL await entitlement settle before showing

Before showing the algorithm-ready glass dialog or persisting the reminded flag, the client MUST await shared VIP settlement and feature-catalog ensure for the current bound session, then recompute predict display entitlement. While the entitlement settle phase is syncing, the client MUST NOT show the dialog and MUST NOT mark reminded. When settlement completes and entitlement is active (basic∨pro∨VIP), the client MUST NOT show the dialog and MUST NOT mark reminded. Only when settlement is ready, entitlement is inactive, silent affinity is ready, and the baby is not yet reminded, MAY the dialog be shown (then mark reminded on show per existing rules).

弹窗与 mark 前 MUST await VIP settle 与 catalog ensure；syncing 或已 entitle MUST NOT 弹、MUST NOT mark。

#### Scenario: VIP 迟到不误弹

- **WHEN** 静默亲和已就绪，首帧 VIP 仍 loading，随后 settle 为 isVip=true
- **THEN** 客户端 MUST NOT 展示算法就绪弹窗
- **AND** MUST NOT 写入该宝宝已提醒标记

#### Scenario: settle 后未开通才弹

- **WHEN** VIP 与 catalog 均已 ready，用户非 VIP 且无 basic/pro 有效权益，静默亲和就绪且未提醒
- **THEN** 客户端 MAY 展示弹窗并在展示时 mark 已提醒
