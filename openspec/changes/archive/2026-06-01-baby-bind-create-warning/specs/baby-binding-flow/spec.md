## ADDED Requirements

### Requirement: 创建新宝宝前风险提示
The system MUST show a confirmation warning before creating a new baby profile.
当用户在宝宝信息绑定页面选择“创建新宝宝”并提交时，系统必须先提示：若家人已创建宝宝，应优先使用“绑定宝宝”功能，不得直接无提示创建。

#### Scenario: 用户在创建前看到提醒并可取消
- **WHEN** 用户在“创建新宝宝”模式下点击提交创建
- **THEN** 系统显示提醒弹层，包含“若家人已创建宝宝，请使用绑定宝宝功能，不要重复创建”语义，并允许用户取消

#### Scenario: 用户确认后继续创建
- **WHEN** 用户在提醒弹层中选择继续创建
- **THEN** 系统按现有创建流程调用创建接口，不改变既有请求字段与成功跳转行为

### Requirement: 绑定入口文案一致性
The system SHALL use consistent binding copy as "绑定宝宝" in baby binding entry points.
宝宝信息绑定相关入口与操作文案必须统一使用“绑定宝宝”，不得继续展示“绑定宝宝ID”。

#### Scenario: 绑定模式文案展示一致
- **WHEN** 用户进入宝宝信息绑定页面
- **THEN** 页面中绑定入口按钮、标签或标题展示为“绑定宝宝”
