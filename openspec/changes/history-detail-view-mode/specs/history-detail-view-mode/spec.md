## ADDED Requirements

### Requirement: 详情页默认只读预览

The system SHALL open the history detail screen in a read-only preview mode and MUST NOT present editable form controls until the user explicitly enters edit mode. 系统打开历史详情页时**必须**处于**只读预览**模式；在用户明确进入编辑模式之前，**不得**展示可编辑表单控件（备注输入框、时间修改按钮、保存按钮等）。

#### Scenario: 从主页进入详情

- **WHEN** 用户从主页历史列表点击某条记录进入详情页且记录加载成功
- **THEN** 页面必须展示该条记录的只读详细信息，且不得默认聚焦或展示编辑表单

#### Scenario: 用户进入编辑

- **WHEN** 用户在预览模式点击 AppBar 上的编辑操作
- **THEN** 页面必须切换为编辑模式并展示与 `eventNumber` 类型一致的现有可编辑字段

### Requirement: 预览模式结构化展示

The system SHALL display structured read-only fields in preview mode aligned with eventNumber semantics (times, usage, duration, remark). 预览模式必须按 `eventNumber` 语义结构化展示只读字段（起止/结束时间、用量、用时、备注等），时间格式必须完整可读（如 `yyyy-MM-dd HH:mm:ss` 级别）。

#### Scenario: 计时类记录预览

- **WHEN** 记录 `eventNumber == 0`
- **THEN** 预览必须包含开始时间、结束状态或结束时间、已结束时的用时文案、备注（若有）

### Requirement: 编辑取消与未保存返回

The system SHALL allow canceling edit mode back to preview and MUST confirm when discarding unsaved edits on back navigation. 系统必须允许从编辑模式**取消**回到预览；编辑中存在未保存修改时，用户通过返回离开必须经确认后方可放弃修改。

#### Scenario: 取消编辑

- **WHEN** 用户在编辑模式点击取消且未保存
- **THEN** 必须回到预览模式并恢复为进入编辑前的字段值

#### Scenario: 编辑中返回

- **WHEN** 用户在编辑模式修改了字段并触发系统返回
- **THEN** 必须提示确认；用户确认放弃后才可离开编辑或关闭页面
