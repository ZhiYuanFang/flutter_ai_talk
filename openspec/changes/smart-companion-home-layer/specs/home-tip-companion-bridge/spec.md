## ADDED Requirements

### Requirement: Done tip card SHALL navigate to companion on whole-card tap

When the home tip panel is in `done` state, a tap on the tip content area (whole card, excluding dedicated close/feedback controls) MUST navigate the home PageView to the smart companion page. 首页小贴士处于 `done` 时，点击整卡内容区（排除关闭/反馈控件）**必须** 将 PageView 切至智能陪伴页。

#### Scenario: done 整卡进入陪伴

- **WHEN** tip `displayState == done` 且用户点击贴士内容区域
- **THEN** PageView MUST animate/jump to the companion page index
- **AND** MUST NOT auto-send a user chat question solely because of the tap（注入 tip 由 session 规则负责）

### Requirement: Streaming tip MUST disable navigation tap

While the tip panel is `streaming`, the client MUST NOT navigate to companion from a tip card tap (tap target disabled or ignored). tip 处于 `streaming` 时 **不得** 因点卡进入陪伴。

#### Scenario: streaming 点按无效

- **WHEN** tip `displayState == streaming` 且用户点击贴士区域
- **THEN** PageView MUST 保持在喂养页
- **AND** MUST NOT 注入未完成 tip

### Requirement: Swipe into companion SHALL carry unconsumed done tip

When the user enters the companion page by horizontal swipe (or left-edge pull tab) and an unconsumed `done` tip exists, the client MUST apply the same tip injection rules as card navigation. 用户横滑或经左缘拉条进入陪伴且存在未消费 done tip 时，**必须** 与点卡相同地注入 tip。

#### Scenario: 右滑进陪伴带 tip

- **WHEN** 喂养页存在未消费 done tip，用户右滑进入陪伴页
- **THEN** 陪伴会话 MUST 注入该 tip 文本并标记消费
