## ADDED Requirements

### Requirement: 登录与注册须勾选协议而非隐含同意

Login and register screens MUST replace implied-consent copy with an unchecked checkbox acknowledging both the user agreement and the privacy policy, each link opening its respective URL. 登录页与注册页必须废除「登录/注册即代表您已阅读并同意」类隐含同意文案；必须提供默认**未勾选**的勾选说明，涵盖《用户协议》与《隐私政策》，且两链接必须分别打开 `AppEnv.userAgreementUrl` 与 `AppEnv.privacyPolicyUrl`。

#### Scenario: 默认未勾选

- **WHEN** 用户打开登录页或注册页且尚未勾选
- **THEN** 协议勾选框必须处于未勾选状态，且界面**不得**展示「登录即代表…」或「注册即代表…」作为唯一同意方式

#### Scenario: 两份文档入口分离

- **WHEN** 用户分别点击《用户协议》与《隐私政策》
- **THEN** 系统必须分别打开用户协议 URL 与隐私政策 URL（不得将二者强行合并为同一文案入口却指向错误文档）

### Requirement: 未勾选时登录须确认并可自动勾选后继续

If the user attempts password/WeChat (or equivalent) login or register submit without checking the agreement box, the client MUST show an explicit confirm dialog; on confirm it MUST check the box and continue the attempted action; on cancel it MUST NOT proceed. 用户未勾选协议即尝试登录（含微信登录）或注册提交时，客户端必须弹出明确确认（同意文案须清晰表达「同意」，不得仅用「好的/我知道了」）；用户确认后必须自动勾选并继续原操作；取消则**不得**继续登录/注册。

#### Scenario: 未勾选点登录弹出确认

- **WHEN** 协议未勾选，且用户点击登录或微信登录
- **THEN** 系统必须展示确认弹窗，且在用户确认前**不得**发起登录请求或拉起微信授权

#### Scenario: 确认后自动勾选并继续

- **WHEN** 用户在上述确认弹窗中确认同意
- **THEN** 系统必须将勾选框置为已勾选，并继续执行刚才触发的登录/注册流程

#### Scenario: 取消确认不登录

- **WHEN** 用户在上述确认弹窗中取消
- **THEN** 勾选框保持未勾选，且**不得**发起登录/注册
