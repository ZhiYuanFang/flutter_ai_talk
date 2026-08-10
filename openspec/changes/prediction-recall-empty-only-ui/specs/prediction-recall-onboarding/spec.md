## MODIFIED Requirements

### Requirement: Prediction page SHALL show recall cards for root event gaps

When the user opens the smart prediction page, the client SHALL show recall onboarding **only if** the prediction-range real history is completely empty (no records) after the range load is ready. If any real history record exists in that source, the client MUST NOT show the onboarding and MUST rely on real data only for prediction. When onboarding is shown, the queue SHALL still cover catalog root events (`parentId == null`) that are not forecast-disabled. Roots the user has skipped (forecast disabled) MUST NOT re-enter the queue until forecast is re-enabled.

进入智能预测页时，客户端 **仅当** 预测 range 真历史在就绪后**完全为空**才展示量身定做；只要存在任意真历史记录，**不得**展示引导，**必须**只靠真数据推演。展示时队列仍覆盖未关推演的根事件；已跳过关推演的根 **不得** 再入队，直至重新开启推演。

#### Scenario: 完全无记录才引导

- **WHEN** 预测 range 已就绪且 items 为空，用户进入智能预测页
- **THEN** UI MUST 展示量身定做引导（悬浮卡流程）

#### Scenario: 有任意真历史不引导

- **WHEN** 预测 range 中存在至少一条真历史记录
- **THEN** UI MUST NOT 展示量身定做引导
- **AND** MUST 按正常预测逻辑仅使用真历史（及既有非引导路径）

#### Scenario: range 未就绪不误开

- **WHEN** 预测 range 仍在首次加载、尚未 ready
- **THEN** 客户端 MUST NOT 仅因「暂时空列表」启动量身定做会话

## ADDED Requirements

### Requirement: Recall onboarding SHALL use a non-swipeable floating card PageView

The onboarding main surface SHALL be a PageView of floating-style cards (one logical step per page). The PageView MUST use non-scrollable physics so the user cannot change pages by horizontal drag. Page changes MUST occur only via programmatic navigation after confirm, skip, thinking continue, or equivalent controls.

量身定做主表面 **必须** 为悬浮感卡片 PageView；**必须** 禁止用户左右拖滑切页；切页 **必须** 仅由确认/跳过/思考继续等控件程序驱动。

#### Scenario: 禁手滑

- **WHEN** 用户在量身定做卡片上左右拖滑
- **THEN** PageView MUST NOT 切换到另一张卡片

#### Scenario: 确认后程序前进

- **WHEN** 用户确认当前根事件卡片
- **THEN** 客户端 MUST 程序切换到该卡思考页或下一流程页（不得依赖用户手滑）
