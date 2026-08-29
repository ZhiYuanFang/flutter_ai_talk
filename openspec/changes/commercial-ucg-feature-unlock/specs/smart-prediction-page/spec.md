## REMOVED Requirements

### Requirement: Auth swipe guide card SHALL omit UCG copy while pause gate is active

**Reason**: UCG 主壳重开，Auth 冷态滑动引导恢复广场指引。

**Migration**: 见本文件 ADDED「Auth 滑动引导大卡 MUST 恢复左滑进广场文案」。

## ADDED Requirements

### Requirement: Auth swipe guide card MUST restore UCG swipe hint copy

When the user is logged-out or unbound on the smart prediction page, the swipe guide card MUST remain visible and MUST include the copy「左滑进广场 · 右滑去喂养」(in addition to any generic swipe headline). The card MUST NOT itself contain action buttons that open login/bind. Locked prediction event overlays (when applicable) MUST follow `prediction-event-lock` and MUST NOT replace this auth guide card.

未登录或未绑定时，预测页滑动引导大卡 **必须** 保留，且文案 **必须** 含「左滑进广场 · 右滑去喂养」；大卡 **不得** 自带登录/绑定按钮。

#### Scenario: 大卡含广场文案

- **WHEN** 用户未登录或未绑定且打开预测页，且 UCG 主壳已重开
- **THEN** 页面 MUST 展示滑动引导大卡
- **AND** 文案 MUST 包含「左滑进广场 · 右滑去喂养」

### Requirement: Prediction page MAY host event lock overlays without restoring tip marquee

The smart prediction page MUST apply commercial event lock overlays per `prediction-event-lock` on real rows. The page MUST NOT reintroduce the bottom tip horizontal marquee removed by `pause-ucg-vip-slim-prediction-chrome`. Care-alert visibility MUST remain non-empty-success-only unless a later change explicitly revises it.

预测页 **必须** 按 `prediction-event-lock` 叠事件锁；**不得** 恢复底 tip 跑马灯；留意卡非空成功态规则 **保持**（除非后续变更显式修改）。

#### Scenario: 无底 tip 跑马灯

- **WHEN** 存在 tip 文案缓存
- **THEN** 预测页 MUST NOT 渲染底部 tip 横向跑马灯
