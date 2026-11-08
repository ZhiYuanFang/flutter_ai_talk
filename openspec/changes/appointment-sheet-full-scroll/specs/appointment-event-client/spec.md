## ADDED Requirements

### Requirement: Appointment next sheet MUST scroll as a whole under short height

The dedicated next-appointment sheet MUST present its body inside a vertically scrollable viewport when content exceeds the sheet’s max height (after keyboard inset and safe padding). The datetime wheel columns, when shown, MUST use a finite fixed height inside that scrollable content and MUST NOT rely solely on an `Expanded` fill that assumes a non-scrolling bounded parent. When the remark field is focused or the soft keyboard is visible, the client MUST still collapse/hide the wheel columns per existing keyboard rules, and MUST keep keyboard avoidance (`respectKeyboardInset` / remark `keyboardLift`). Under landscape or other short viewports, the user MUST be able to scroll to the remark field and confirm action without a vertical RenderFlex overflow of the sheet body. 专用下次预约 sheet 内容超出最大高度（含键盘 inset）时 MUST 整窗纵向可滚；展示中的时间滚轮 MUST 为滚动内容内的有限固定高度，MUST NOT 仅依赖非滚动有界父级上的 Expanded。备注获焦或键盘可见时 MUST 仍按既有规则收起滚轮并保留键盘避让。横屏等矮视口下用户 MUST 能滚到备注与确认，且 MUST NOT 出现 sheet body 纵向 RenderFlex overflow。

#### Scenario: Landscape with keyboard can scroll to confirm

- **WHEN** 横屏打开专用下次预约 sheet 且软键盘升起导致可用内容高度明显小于标题+备注+确认的固有高度
- **THEN** 用户 MUST 能纵向滚动看到备注输入与确认按钮
- **AND** sheet body MUST NOT 因纵向 RenderFlex overflow 而无法布局

#### Scenario: Wheels use fixed height inside scroll content

- **WHEN** 滚轮未收起且 sheet 处于整窗可滚模式
- **THEN** 四列时间滚轮 MUST 以有限固定高度置于可滚内容中
- **AND** MUST NOT 仅依赖父级非滚动有界高度上的 Expanded 填满

#### Scenario: Collapse wheels still works with scroll

- **WHEN** 用户聚焦备注或键盘可见
- **THEN** 四列时间滚轮 MUST 收起或不可见
- **AND** 剩余内容（含备注与确认）MUST 仍处于可滚视口内（若超出最大高度）
