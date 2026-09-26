## ADDED Requirements

### Requirement: Appointment events MUST be excluded from interval-sample prediction

The client MUST NOT apply interval-sample next-occurrence prediction to events with `isAppointment` true (resolved at catalog root). Non-appointment events SHALL keep existing `event-interval-prediction` behavior. Appointment next time MUST follow `appointment-event-client`. 预约事件（按根）**不得** 用间隔样本推演下次；非预约保持既有间隔预测；预约下次时间见 `appointment-event-client`。

#### Scenario: Routine feeding still uses intervals

- **WHEN** 事件 `isAppointment` 为假且满足既有样本门槛
- **THEN** 客户端 MUST 按既有间隔预测规格计算 nextAt

#### Scenario: Appointment skips interval engine

- **WHEN** 根事件 `isAppointment` 为真
- **THEN** 间隔预测引擎 MUST NOT 为该事件输出基于样本间隔的 nextAt
