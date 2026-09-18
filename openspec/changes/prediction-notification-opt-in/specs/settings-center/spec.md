## ADDED Requirements

### Requirement: Settings Center SHALL link to message notification settings when logged in

When the user is logged in, the Settings Center list MUST include a「消息通知」（or equivalent）entry that navigates to the message notification settings page defined by `app-notification-preference`. 已登录时设置中心 **必须** 提供进入消息通知设置页的入口。

#### Scenario: Logged-in user sees entry

- **WHEN** 用户已登录并打开设置中心
- **THEN** 客户端 MUST 展示可进入消息通知说明与开关页的入口
