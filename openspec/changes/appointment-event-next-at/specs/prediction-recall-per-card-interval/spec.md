## ADDED Requirements

### Requirement: Appointment cards MUST supplement next trigger time instead of interval

For appointment prediction cards, the client MUST present next-trigger-time supplement/edit via the dedicated next-appointment sheet as the primary completion path and MUST NOT use the per-card interval supplement as the default path. Non-appointment cards SHALL keep existing per-card interval supplement behavior from `prediction-recall-per-card-interval`. 预约预测卡 **必须** 以专用「下一次预约」sheet 补充/编辑下次时间为主路径；**不得** 以「补充大概多久一次」为默认路径；非预约卡保持既有间隔补充。

#### Scenario: Appointment card opens next-time editor

- **WHEN** 用户在预约预测卡上发起「补充下次」类操作
- **THEN** 客户端 MUST 进入专用下一次预约 sheet，MUST NOT 将间隔 picker 作为该卡的默认补充 UI

#### Scenario: Non-appointment interval CTA unchanged

- **WHEN** 非预约热态卡满足既有「补充大概多久一次」条件
- **THEN** 客户端 MUST 仍按既有间隔补充规格展示与写入种子
