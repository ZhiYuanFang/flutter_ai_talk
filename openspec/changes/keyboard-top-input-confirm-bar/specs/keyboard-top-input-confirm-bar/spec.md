## ADDED Requirements

### Requirement: 统一键盘顶部输入确认条展示
The system SHALL present a keyboard-top input confirm bar for managed text input fields when they gain focus.
系统在受管控输入框获得焦点时，必须在键盘上方展示统一输入确认条；该确认条至少包含左侧输入文本显示区与右侧“确定”按钮。系统在输入框失焦或键盘关闭后不得继续显示该确认条。

#### Scenario: 聚焦后展示确认条
- **WHEN** 用户在受管控页面或弹层中点击可编辑输入框并触发键盘弹出
- **THEN** 系统在键盘上方显示输入确认条，且右侧提供可点击“确定”按钮

#### Scenario: 确认条展示当前输入场景提示
- **WHEN** 用户在确认条中尚未输入任何内容
- **THEN** 确认条左侧文本区以占位样式展示该输入场景的 hint，说明当前输入框所代表的内容（如账号、密码、备注等）
- **WHEN** 用户已输入内容
- **THEN** 确认条左侧文本区展示当前输入内容（密码场景仍为脱敏展示），不再显示 hint

### Requirement: 聚焦输入不得顶起主界面
The system MUST keep the managed screen layout stable and MUST NOT push up the primary content area due to keyboard appearance.
在纳入该能力的输入场景中，系统必须保持主界面布局稳定，不得因键盘弹出而将主要内容区域整体顶起；输入行为应由键盘顶部确认条承接。

#### Scenario: 键盘弹出时布局稳定
- **WHEN** 用户在受管控输入场景中聚焦输入框并唤起键盘
- **THEN** 主体内容区域位置保持稳定，不发生整体上移跳动

### Requirement: 确认动作必须回填并触发场景提交
The system SHALL write confirmed text back to the target input controller and SHALL invoke the mapped submit callback for that input context.
当用户点击“确定”时，系统必须将确认条中的文本回填到目标输入框，并触发该场景映射的提交流程（如原 `onSubmitted`、确认按钮处理函数或等效业务提交回调）。

#### Scenario: 点击确定完成回填与提交
- **WHEN** 用户在确认条中点击“确定”
- **THEN** 系统先更新目标输入框内容，再执行该场景原有提交逻辑

### Requirement: 保持现有输入能力与敏感输入安全语义
The system MUST preserve existing input behaviors and MUST mask sensitive content in the keyboard-top display for password contexts.
系统必须保留现有输入能力，包括校验规则、只读态、禁用态、密码态、已有业务按钮与提交流程；在密码输入场景中，键盘顶部文本显示必须采用脱敏展示，不得明文暴露。

#### Scenario: 密码输入场景脱敏展示
- **WHEN** 用户在密码输入框中输入并触发键盘顶部确认条
- **THEN** 确认条显示内容为脱敏文本，且确认后仍能将真实值回填并完成提交
