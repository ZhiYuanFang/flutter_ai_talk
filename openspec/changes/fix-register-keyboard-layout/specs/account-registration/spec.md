## MODIFIED Requirements

### Requirement: 注册页视觉风格必须与登录页一致
The registration page MUST keep visual style consistent with the login page.

注册页在布局层级、输入框样式、按钮样式、主题色与间距节奏上必须与登录页保持统一，不得引入明显风格割裂；主表单区域 MUST 采用与登录页相同的贴底布局（`Column` 在撑满视口高度的滚动子树内 `mainAxisAlignment: end`），使多字段表单靠近视口底部而非自上而下单列堆叠。

#### Scenario: 关键视觉元素一致
- **WHEN** 注册页渲染标题、输入框、主按钮与背景
- **THEN** 这些关键元素的样式令牌与登录页保持一致或复用同一组件实现

#### Scenario: 交互状态一致
- **WHEN** 用户触发输入框聚焦、按钮禁用/可用、错误提示等交互状态
- **THEN** 注册页交互反馈与登录页遵循同一视觉与动效规范

#### Scenario: 主表单贴底布局与登录页一致
- **WHEN** 注册页在标准手机竖屏下渲染完整表单
- **THEN** 账号、密码、确认密码与注册按钮组成的表单块 MUST 贴近视口底部对齐
- **AND** 布局策略 MUST 与登录页账号密码表单一致（贴底 Column，而非默认顶对齐）

## ADDED Requirements

### Requirement: 注册页确认密码聚焦时 MUST 可稳定输入
The registration page SHALL allow reliable text entry when the confirm-password field is focused and the system keyboard is visible.

在 Android 14 及同等 IME inset 行为环境下，用户聚焦「确认密码」并弹出系统键盘时，页面 MUST NOT 因布局顶起循环而卡死、无响应或导致应用进程被杀；确认密码输入框 MUST 保持可编辑直至用户完成输入或主动收起键盘。

#### Scenario: Android 14 真机确认密码可输入
- **WHEN** 用户在 Android 14 设备上打开注册页并聚焦「确认密码」
- **THEN** 系统键盘 SHALL 正常弹出
- **AND** 用户 SHALL 可持续键入字符
- **AND** 应用 MUST NOT 出现长时间无响应或连接断开

#### Scenario: 键盘下一项进入确认密码
- **WHEN** 用户在「密码」字段通过键盘「下一项」将焦点移至「确认密码」
- **THEN** 焦点 MUST 落于确认密码框
- **AND** 输入行为 MUST 与直接点击确认密码框一致且可正常输入
