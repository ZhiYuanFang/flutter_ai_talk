## ADDED Requirements

### Requirement: In-app UCG unread dots SHALL use fixed red via AppColor

The shell bottom **消息** tab unread indicator and the prediction-page UCG square EdgeDock ball unread indicator MUST use a fixed red color from `AppColor` (e.g. `AppColor.unreadDot`), and MUST NOT use `ColorScheme.primary` / `AppColor.primary` so the dots do not change with the user theme palette. Launcher icon badge color remains OS-controlled and is out of scope.

消息 Tab 未读红点与预测页广场悬浮球未读红点 **必须** 使用 `AppColor` 固定红语义色，**必须 NOT** 跟随主题 primary。桌面图标角标颜色由系统绘制，不在本需求范围。

#### Scenario: 消息 Tab 红点不跟主题

- **WHEN** 用户切换应用主题色且存在 UCG 未读（`ucgUnreadCountProvider > 0`）
- **THEN** 底部「消息」未读点 MUST 仍为固定红
- **AND** MUST NOT 变为新的 primary 色

#### Scenario: 悬浮球红点不跟主题

- **WHEN** 预测页广场球展示未读点且用户已换主题
- **THEN** 球上未读点 MUST 为同一固定红语义色
- **AND** MUST NOT 使用 `AppColor.primary`
