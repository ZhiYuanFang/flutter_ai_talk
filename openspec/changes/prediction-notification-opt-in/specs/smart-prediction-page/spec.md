## ADDED Requirements

### Requirement: Portrait prediction page SHALL show a session-dismissible notification opt-in banner when unauthorized

On the smart prediction page in **portrait** orientation, when the user is logged in, the app notification preference is enabled, OS notification permission is not granted, and the user has not dismissed the banner in the current app session, the client MUST show a banner at the top of the main content column (above the「接下来3小时」timeline when that timeline is shown) that explains enabling notifications allows service alerts when events are about to happen so the user need not watch the phone constantly and is less likely to forget recording. The banner MUST provide a control to start authorization (request permission or open system settings when permanently denied) and MUST provide a dismiss control that hides the banner for the **current session only**. In **landscape** orientation the client MUST NOT show this banner. 竖屏且未授权等条件满足时 **必须** 在正文顶展示可会话关闭的引导横条；横屏 **不得** 展示。

#### Scenario: Show banner when OS notifications off

- **WHEN** 已登录用户在竖屏预测页且系统通知未授权、应用偏好开启、本会话未关闭横条
- **THEN** 客户端 MUST 在正文顶部展示引导横条（含价值说明与开启入口）
- **AND** MUST 提供关闭控件，关闭后本会话内 MUST NOT 再展示该横条

#### Scenario: No banner in landscape

- **WHEN** 预测页处于横屏（含投屏）
- **THEN** 客户端 MUST NOT 展示该通知引导横条

#### Scenario: No banner when preference off

- **WHEN** 应用层消息通知偏好已关闭
- **THEN** 预测页 MUST NOT 展示该引导横条

#### Scenario: Banner hidden after grant

- **WHEN** 用户经横条或系统设置完成通知授权且探测为已授权
- **THEN** 客户端 MUST 隐藏该横条
