## ADDED Requirements

### Requirement: While recall onboarding is visible chrome panels MUST be hidden

While the recall onboarding layer is visible on the smart prediction page, the client MUST NOT render the care-alert（值得留意）panel, the next-three-hours timeline, or the bottom tip marquee. The baby identity header MAY remain visible.

量身定做可见期间，智能预测页 **不得** 渲染值得留意、接下来 3 小时时间线、底部 tip 跑马灯；身份顶栏 MAY 保留。

#### Scenario: 引导中无三块 chrome

- **WHEN** 量身定做引导正在展示
- **THEN** UI MUST NOT 展示值得留意面板
- **AND** MUST NOT 展示「接下来3小时」时间线
- **AND** MUST NOT 展示底部 tip 跑马灯

#### Scenario: 引导结束后可恢复

- **WHEN** 用户完成收尾 CTA 关闭量身定做
- **THEN** 值得留意 / 三小时 / 底 tip 可按原有有数据逻辑重新展示
