## ADDED Requirements

### Requirement: Cold prediction page SHALL layer auth or bind gate over skeleton

While the smart prediction page is in a cold demo state due to not being logged in or not being bound, the client SHALL keep the demo skeleton and fixed healthy care-alert card visible underneath the applicable login or bind gate Dialog from `prediction-gate-dialog`. Layout toggle and identity header MAY remain.

因未登录或未绑定而处于冷态时，客户端 **必须** 在登录/绑定引导 Dialog 下方保留骨架与固定健康留意卡；布局切换与身份顶栏 MAY 保留。

#### Scenario: 未登录骨架与登录 Dialog 同屏

- **WHEN** 用户未登录打开智能预测页且登录引导可见
- **THEN** Dialog 下方 MUST 仍展示骨架预测行与假留意卡

#### Scenario: 未绑定骨架与绑定 Dialog 同屏

- **WHEN** 用户已登录未绑定且绑定引导可见
- **THEN** Dialog 下方 MUST 仍展示骨架预测行与假留意卡
