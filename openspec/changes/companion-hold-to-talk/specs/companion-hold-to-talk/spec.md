## ADDED Requirements

### Requirement: Companion composer SHALL toggle text and hold-to-talk modes

On non-Web platforms, the smart companion input bar MUST provide a left-side control to switch between text input and hold-to-talk mode. The client MUST persist the last selected mode in a companion-specific store and restore it on next open when the mode remains available. 非 Web 上陪伴输入条左侧 **必须** 可切换文字 / 按住说话，并 **必须** 用陪伴专用存储记忆上次模式。

#### Scenario: 切换到按住说话并记忆

- **WHEN** 用户在 Android/iOS 陪伴页将模式切到按住说话后杀进程再进陪伴页
- **THEN** 输入区 MUST 恢复为按住说话模式（在仍具备语音可用性时）

#### Scenario: 切换回文字

- **WHEN** 用户在按住说话模式下点击左侧键盘/文字入口
- **THEN** 输入区 MUST 显示文字输入框与发送控件

### Requirement: Web companion MUST NOT offer hold-to-talk

On Web, the companion page MUST render text input only and MUST NOT show a control to enter hold-to-talk mode. Web 陪伴页 **必须** 仅文字输入，**不得** 提供按住说话入口。

#### Scenario: Web 无语音切换

- **WHEN** 用户在 Web 打开智能陪伴页
- **THEN** UI MUST NOT 展示切换至按住说话的控件
- **AND** MUST NOT 启动麦克风采集

### Requirement: Hold-to-talk SHALL show floating live transcript above the bar

While the user is holding to speak in companion hold-to-talk mode, the client MUST show a floating transcript surface above the input bar that updates with partial recognition text (or a listening placeholder when partial is empty). 按住说话期间 **必须** 在输入条上方浮动展示实时转写（无 partial 时可为「聆听中」类占位）。

#### Scenario: 按住出现浮动转写

- **WHEN** 用户按住陪伴「按住 说话」且 ASR 产出 partial
- **THEN** 浮动层 MUST 展示该 partial 并随增量更新

### Requirement: Release inside send zone SHALL send transcript as companion question

When the user releases the pointer while not in cancel state and the final transcript is non-empty, the client MUST send that text as a Clinic companion question (same path as typed send) and MUST hide the floating transcript after the user message is shown in the conversation list. 非取消态松手且转写非空时 **必须** 作为陪伴 question 发送，并在列表展示用户句后 **必须** 隐藏浮动转写。

#### Scenario: 松手发送并隐藏浮动条

- **WHEN** 用户按住说话、未进入取消态、松手且转写非空
- **THEN** 客户端 MUST 发送 Clinic question
- **AND** 对话列表 MUST 出现对应用户句
- **AND** 浮动转写 MUST 隐藏

#### Scenario: 空转写不发送

- **WHEN** 用户松手且转写为空且非取消态
- **THEN** 客户端 MUST NOT 发送 question
- **AND** 浮动转写 MUST 隐藏

### Requirement: Slide-up cancel SHALL align with feeding cancel semantics

During an active companion hold, when the pointer moves upward past the cancel threshold, the client MUST enter cancel state with distinct UI copy (e.g.「松开取消」). Release in cancel state MUST end recognition without sending a companion question and MUST hide the floating transcript. Moving back below the threshold before release MUST restore send-on-release state. 按住期间上滑超过取消阈值 **必须** 进入取消态；取消态松手 **必须** 不发送；移回阈值内 **必须** 恢复可发送。

#### Scenario: 上滑后松手取消

- **WHEN** 用户已按住说话并将手指上滑超过取消阈值后松手
- **THEN** 客户端 MUST NOT 发送 Clinic question
- **AND** 浮动转写 MUST 隐藏

#### Scenario: 上滑后下移恢复发送

- **WHEN** 用户进入取消态后仍按住并下移回发送区再松手，且转写非空
- **THEN** 客户端 MUST 按发送路径提交转写

#### Scenario: 取消态可见反馈

- **WHEN** 用户处于按住流程且指针在取消区
- **THEN** 按住条文案 MUST 表明松手将取消（不得仍仅显示「松开发送」）

### Requirement: Companion hold-to-talk MUST NOT use the feeding voice orb as primary control

The companion hold-to-talk UI MUST use the composer bar hold target and MUST NOT present the feeding-home large voice orb as the primary hold control. 陪伴按住说话 **必须** 使用输入条热区，**不得** 以喂养页大语音球作为主控。

#### Scenario: 无语音球主控

- **WHEN** 用户处于陪伴按住说话模式
- **THEN** UI MUST NOT 渲染喂养页同款大圆形语音球作为主输入
