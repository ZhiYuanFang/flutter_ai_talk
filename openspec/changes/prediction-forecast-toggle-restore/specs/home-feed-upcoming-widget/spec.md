## ADDED Requirements

### Requirement: Home widget predictions SHALL honor forecast-disabled event ids

When building the desktop home widget prediction rows (hero and follow-up prediction rows), the client MUST exclude events whose forecast toggle is OFF according to the same local disabled set used by the smart prediction page. Changing a forecast toggle MUST schedule a home widget sync so the native widget reflects the new set without requiring an app restart.

桌面小组件预测行 **必须** 排除推演关闭的事件（与预测页同一本地集合）；开关变更后 **必须** 调度小组件同步。

#### Scenario: 关闭后小组件不再展示该事件

- **WHEN** 用户关闭事件 A 的推演且小组件同步完成
- **THEN** 小组件 hero/后续预测行 MUST NOT 再以 A 作为预测展示项

#### Scenario: 开关变更触发同步

- **WHEN** 用户切换任一事件的推演开关
- **THEN** 客户端 MUST 调度既有 home widget sync 路径更新桌面展示
