## ADDED Requirements

### Requirement: Auth 冷态预测页 MUST 用滑动引导大卡替换留意与接下来3小时

When the user is not logged in, or is logged in but unbound, the smart prediction page MUST hide the care-alert（值得留意）panel and the next-three-hours（接下来3小时）panel, including any demo/skeleton variants of those panels. In their place the client MUST show a single large guide card that instructs the user to swipe left to the square（UCG）page and swipe right to the feeding page. The guide card MUST NOT include action buttons, MUST NOT navigate on tap, and MUST NOT open the login or bind gate by itself. The prediction event demo-skeleton grid MUST remain visible below the guide card. Left and right chevron/arrow affordances on the guide card MUST continuously animate with horizontal motion and a heartbeat-style scale pulse to draw attention. When the user is logged in and bound, care-alert and next-three-hours behavior MUST remain as before（including demo panels during bound empty-history onboarding）.

未登录或已登录未绑定时，智能预测页 **必须** 隐藏「值得留意」与「接下来3小时」面板（含其演示/骨架变体），并代之以一张滑动引导大卡，提示左滑进广场、右滑进喂养。大卡 **不得** 含操作按钮、**不得** 因点击导航、**不得** 自行打开登录/绑定门闸。大卡下方 **必须** 仍展示预测事件冷态骨架网格。大卡左右箭头 **必须** 持续水平位移并配合心跳式缩放以吸睛。已登录已绑定时，值得留意与接下来3小时行为 **必须** 保持原状（含已绑定空历史量身定做期间的演示面板）。

#### Scenario: 未登录展示滑动引导大卡

- **WHEN** 用户未登录并进入智能预测页
- **THEN** UI MUST NOT 展示「值得留意」面板
- **AND** MUST NOT 展示「接下来3小时」面板
- **AND** MUST 展示滑动引导大卡（含左滑广场 / 右滑喂养说明）
- **AND** MUST 仍展示预测事件骨架网格
- **AND** 大卡 MUST NOT 含按钮

#### Scenario: 已登录未绑定同样替换

- **WHEN** 用户已登录、无可用 deviceNo，进入智能预测页
- **THEN** UI MUST 与未登录相同：滑动引导大卡替换留意与接下来3小时，并保留骨架网格

#### Scenario: 已绑定空历史不替换为滑动引导

- **WHEN** 用户已登录已绑定且处于空历史量身定做冷态
- **THEN** UI MUST NOT 因本需求强制展示滑动引导大卡替代留意/接下来3小时
- **AND** MAY 继续展示演示留意卡与接下来3小时（或既有量身定做 chrome）

#### Scenario: 箭头持续动效

- **WHEN** 滑动引导大卡可见
- **THEN** 左右箭头 affordance MUST 持续播放水平位移动画与心跳式缩放动画
