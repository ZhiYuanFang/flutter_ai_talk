## ADDED Requirements

### Requirement: Trial success chrome SHALL omit retired unlock-hub expiry guidance

After a successful `trial/start` for predict capability when the client shows a success confirmation, that confirmation MUST NOT instruct the user to view entitlement expiry in the feature unlock hub. Expiry presentation, if any, MUST rely on in-wall / catalog-driven chrome instead of hub navigation.

试用成功确认 MUST NOT 引导用户到开通中心查看到期；到期展示若有 MUST 依赖墙内/catalog 面，不得依赖 Hub。

#### Scenario: 试用成功不进 Hub

- **WHEN** 预测能力试用 start 成功并弹出确认
- **THEN** 客户端 MUST NOT 将用户导航至 `/features/unlock`
- **AND** 确认文案 MUST NOT 要求用户去开通中心查看
