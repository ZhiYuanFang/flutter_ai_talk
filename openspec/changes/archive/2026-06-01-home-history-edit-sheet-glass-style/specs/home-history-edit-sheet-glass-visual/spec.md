## ADDED Requirements

### Requirement: 玻璃拟态编辑卡片容器

The client SHALL present the home history edit sheet content inside a glassmorphism-style panel with background blur, semi-transparent fill, rounded corners, and a subtle luminous border. 编辑 Sheet 主体 MUST 使用**磨砂玻璃**效果（背景模糊 + 半透明填充 + 圆角 + 微光描边），与参考稿一致的卡片式弹层，而非默认 Material 纯色 bottom sheet 面板。

#### Scenario: 打开编辑 Sheet

- **WHEN** 用户点击一条可编辑历史记录
- **THEN** 客户端 MUST 在半透明遮罩上展示玻璃质感圆角卡片容器，且卡片内承载全部编辑控件

#### Scenario: 明暗主题

- **WHEN** 用户切换 shell 明暗主题后打开编辑 Sheet
- **THEN** 玻璃容器与文字 MUST 仍保持可读对比度，且继续使用主题语义色（非写死单一 hex）

### Requirement: 居中 Logo 与标题头部

The client SHALL display a top-centered event logo and event name title below it, with a close control in the top-right corner. 头部 MUST：**居中**展示事件 Logo 与大号事件名；**右上角** MUST 提供关闭（×）控件，点击 MUST 触发与返回等价的关闭流程（含未保存确认）。

#### Scenario: 关闭按钮

- **WHEN** 用户点击右上角关闭
- **THEN** 客户端 MUST 执行与系统返回一致的 dismiss 逻辑（含脏表单确认）

### Requirement: 玻璃质感时间输入条

The client SHALL render editable time fields as labeled glass-style rows showing large `HH:mm` text and a trailing pencil/edit icon. 「开始时间」「结束时间」等标签 MUST 位于输入条**上方**；输入条 MUST 为玻璃边框样式，左侧（或中部）展示大号 **`HH:mm`**，右侧 MUST 展示**铅笔/编辑**图标；点击整条 MUST 仍打开现有 Cupertino 时分滚轮子 Sheet。

#### Scenario: 点击时间条

- **WHEN** 用户点击开始或结束时间玻璃条且字段可编辑
- **THEN** 客户端 MUST 打开时分滚轮选择器，且 MUST NOT 提供日历日修改

### Requirement: 底栏取消与保存布局

The client SHALL place **Cancel** as plain text on the bottom-left and **Save** as a solid primary pill button on the bottom-right of the edit sheet. 底栏 MUST 为**取消**（左，文本按钮）与**保存**（右，实心圆角 pill）；保存 MUST 触发既有校验与 update 流程。

#### Scenario: 点击取消

- **WHEN** 用户点击取消且无未保存变更
- **THEN** Sheet MUST 关闭

#### Scenario: 点击保存

- **WHEN** 用户点击保存且校验通过
- **THEN** 客户端 MUST 按现有规则提交 update 并关闭 Sheet

### Requirement: 次要操作不抢占主 CTA

The client MUST style destructive or secondary actions (delete, stop timing) so they do not replace the cancel/save bottom bar layout. **删除**、**停止计时**等次要操作 MUST 使用次级样式（如文本按钮或描边按钮），且 MUST NOT 占据底栏「保存」pill 的位置。

#### Scenario: 可删除记录

- **WHEN** 非 pending 记录打开编辑 Sheet
- **THEN** 用户 MUST 仍能找到删除入口，且底栏 MUST 保留取消/保存左右布局
