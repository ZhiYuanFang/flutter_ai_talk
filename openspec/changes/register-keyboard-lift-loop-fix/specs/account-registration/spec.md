## MODIFIED Requirements

### Requirement: 注册页确认密码聚焦时 MUST 可稳定输入
The registration page SHALL allow reliable text entry when any password field (password or confirm-password) is focused and the system keyboard is visible.

在 Android 14 及同等 IME inset 行为环境下，用户聚焦「密码」或「确认密码」并弹出系统键盘时，页面 MUST NOT 因布局顶起循环而卡死、无响应或导致应用进程被杀；被聚焦的密码类输入框 MUST 保持可编辑直至用户完成输入或主动收起键盘。内联 auth 键盘顶起 MUST NOT 在 Widget `build()` 方法内注册 postFrameCallback 或等效副作用调度。

#### Scenario: Android 14 真机确认密码可输入
- **WHEN** 用户在 Android 14 设备上打开注册页并聚焦「确认密码」
- **THEN** 系统键盘 SHALL 正常弹出
- **AND** 用户 SHALL 可持续键入字符
- **AND** 应用 MUST NOT 出现长时间无响应或连接断开

#### Scenario: Android 14 真机密码可输入
- **WHEN** 用户在 Android 14 设备上打开注册页并聚焦「密码」
- **THEN** 系统键盘 SHALL 正常弹出
- **AND** 密码输入框 MUST 被顶起至键盘上方且可持续键入
- **AND** 应用 MUST NOT 出现长时间无响应或连接断开

#### Scenario: 键盘下一项进入确认密码
- **WHEN** 用户在「密码」字段通过键盘「下一项」将焦点移至「确认密码」
- **THEN** 焦点 MUST 落于确认密码框
- **AND** 输入行为 MUST 与直接点击确认密码框一致且可正常输入

#### Scenario: 键盘 inset 动画期间不得 build 副作用循环顶起
- **WHEN** 注册页已聚焦任一密码类字段且系统键盘 inset 在弹出动画中逐帧变化
- **THEN** 客户端 MUST NOT 在每次 `build()` 中重复调度键盘顶起
- **AND** 顶起调度 MUST 仅在 inset 实质变化或聚焦变化时触发

## ADDED Requirements

### Requirement: 内联 auth 键盘顶起 MUST 幂等且可共享
Inline auth pages (register, login, change-password, baby-bind) SHALL share a single keyboard-lift scheduling path that is idempotent within a focus session.

注册、登录、改密、绑定等内联 auth 页 MUST 共用同一套键盘顶起调度 helper；同一聚焦字段在单次键盘弹出周期内 MUST NOT 因重复 `animateTo` 叠加导致 layout 震荡。

#### Scenario: 连续 inset 变化不叠加滚动动画
- **WHEN** 用户在注册页聚焦密码字段且 `viewInsets.bottom` 在 300ms 内连续变化
- **THEN** 客户端 MUST 合并或跳过冗余顶起请求
- **AND** `ScrollController` MUST NOT 同时运行多个冲突的顶起动画

#### Scenario: 登录页同路径受益
- **WHEN** 用户在登录页聚焦密码字段并弹出系统键盘
- **THEN** 顶起行为 MUST 与注册页采用相同 helper 且 MUST NOT 出现卡死或无响应
