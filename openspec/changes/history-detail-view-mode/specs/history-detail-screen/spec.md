## ADDED Requirements

### Requirement: 编辑入口与底部保存

The system SHALL provide an explicit edit action in the AppBar during preview mode and MUST keep the primary save action as a bottom filled button in edit mode. 预览模式下 AppBar **必须**提供明确的**编辑**入口；编辑模式下**必须**在页面底部保留**保存**按钮作为主要提交操作（不得仅在 AppBar 提供保存）。

#### Scenario: 预览模式无保存按钮

- **WHEN** 详情页处于预览模式
- **THEN** 页面底部不得显示「保存」按钮

#### Scenario: 编辑模式保存

- **WHEN** 用户处于编辑模式并点击底部保存且校验通过
- **THEN** 行为必须与变更前一致（调用更新接口，成功则关闭详情并通知列表刷新）

### Requirement: 不展示创建时间

The system MUST NOT display record createdAt or a「创建时间」label on the history detail screen in either preview or edit mode. 历史详情页在**预览**与**编辑**两种模式下**均不得**展示记录的 `createdAt` 或「创建时间」类文案。

#### Scenario: 加载成功后的详情页

- **WHEN** 详情记录加载完成并渲染预览或编辑内容
- **THEN** 界面中不得出现基于 `createdAt` 的只读展示行
