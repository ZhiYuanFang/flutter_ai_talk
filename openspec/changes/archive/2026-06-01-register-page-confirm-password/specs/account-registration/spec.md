## ADDED Requirements

### Requirement: 注册入口必须跳转到独立注册页
The app MUST navigate to a dedicated registration page when user taps "注册账号" on the login page.

当用户在登录页点击“注册账号”时，系统必须进入独立注册页面，并提供明确的返回路径回到登录页。

#### Scenario: 从登录页进入注册页
- **WHEN** 用户在登录页点击“注册账号”按钮
- **THEN** 系统进入独立注册页，而不是在登录页内联展开注册表单

#### Scenario: 从注册页返回登录页
- **WHEN** 用户在注册页执行返回操作
- **THEN** 系统返回登录页且不破坏原有登录流程状态

### Requirement: 注册表单必须校验确认密码一致性
The registration form SHALL require confirm-password to match password before submission.

注册页必须包含“密码”和“确认密码”字段；当两者不一致时，系统不得发起注册请求，且必须展示可理解的错误提示。

#### Scenario: 密码与确认密码不一致
- **WHEN** 用户输入的密码与确认密码不同并点击注册提交
- **THEN** 系统阻止提交并在表单中提示“确认密码与密码不一致”或同等语义文案

#### Scenario: 密码与确认密码一致
- **WHEN** 用户输入的密码与确认密码一致并满足其他字段校验
- **THEN** 系统允许继续执行注册提交流程

### Requirement: 注册页视觉风格必须与登录页一致
The registration page MUST keep visual style consistent with the login page.

注册页在布局层级、输入框样式、按钮样式、主题色与间距节奏上必须与登录页保持统一，不得引入明显风格割裂。

#### Scenario: 关键视觉元素一致
- **WHEN** 注册页渲染标题、输入框、主按钮与背景
- **THEN** 这些关键元素的样式令牌与登录页保持一致或复用同一组件实现

#### Scenario: 交互状态一致
- **WHEN** 用户触发输入框聚焦、按钮禁用/可用、错误提示等交互状态
- **THEN** 注册页交互反馈与登录页遵循同一视觉与动效规范