## ADDED Requirements

### Requirement: 绑定宝宝输入区辅助说明
The system MUST show helper copy under the baby ID input field on the bind-baby screen.
在绑定宝宝页面的“输入宝宝ID”输入框下方，系统必须展示一行小字说明，帮助用户理解宝宝ID来源。

#### Scenario: 进入绑定模式时显示说明
- **WHEN** 用户进入“绑定宝宝”模式并看到宝宝ID输入框
- **THEN** 输入框下方展示小字文案“从你的家人那查看宝宝信息，复制宝宝id输入”

### Requirement: 文案新增不影响绑定流程
The system SHALL keep existing bind flow behavior unchanged when adding helper copy.
新增辅助说明后，系统必须保持原有绑定提交、参数与成功返回行为不变。

#### Scenario: 输入并提交绑定行为保持不变
- **WHEN** 用户按原流程输入宝宝ID并点击确认绑定
- **THEN** 页面仍按既有流程发起绑定请求并处理结果，不因新增文案改变逻辑
