## ADDED Requirements

### Requirement: 页面进入与返回不得默认聚焦输入框
The system MUST NOT auto-focus managed text input fields when entering a page or returning to the current page.
系统在进入页面或从子页面返回当前页面时，必须不得默认聚焦受管控输入框，且不得因此自动弹出键盘。

#### Scenario: 首次进入页面不自动弹键盘
- **WHEN** 用户首次进入包含输入框的受管控页面
- **THEN** 输入框默认不获取焦点，键盘不自动弹出

#### Scenario: 返回当前页面不自动弹键盘
- **WHEN** 用户从下级页面返回到包含输入框的当前页面
- **THEN** 输入框不被动恢复焦点，键盘不自动弹出

### Requirement: 键盘弹出必须由用户显式输入动作触发
The system SHALL show the keyboard only after explicit user interaction with a target input field.
系统必须仅在用户显式点击或触发目标输入框时才允许聚焦并弹出键盘，不得由页面生命周期被动触发。

#### Scenario: 用户点击输入框后允许弹键盘
- **WHEN** 用户主动点击输入框
- **THEN** 输入框获取焦点并正常弹出键盘

### Requirement: 输入业务能力保持不变
The system SHALL preserve existing validation and submit behavior while changing only default focus timing.
系统在调整默认焦点时机后，必须保持原有输入功能不变，包括校验规则、提交流程、错误提示与按钮行为。

#### Scenario: 焦点策略调整后仍可正常提交
- **WHEN** 用户主动聚焦输入并执行提交
- **THEN** 系统按原逻辑完成校验与提交，结果与改动前一致
