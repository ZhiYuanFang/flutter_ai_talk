## ADDED Requirements

### Requirement: Tip drag handle MUST include the top badge

While the tip is expanded, dragging MUST treat the top Pangbao round badge and the tip card body as one draggable unit;「关闭」and「对话」MUST remain non-drag controls. 展开态拖动 **必须** 将顶部胖宝圆标与正文卡视为同一拖动单元；「关闭」「对话」**不得** 作为拖动手柄。

#### Scenario: 拖顶标移动整卡

- **WHEN** tip expanded 可见
- **AND** 用户按住顶标并拖动超过点击 slop
- **THEN** 整卡（含顶标）MUST 跟随位移

### Requirement: Pointer on tip bounds MUST block PageView swipe

While a pointer is down within the tip’s hittable bounds (expanded card+badge, collapsed circle, or docked handle), the client MUST prevent the home PageView from consuming that gesture for horizontal page changes until the pointer is released or cancelled. tip 有界命中区内指针按下期间，客户端 **必须** 阻止 PageView 横滑切页，直至抬起或取消。

#### Scenario: 在 tip 上横滑不切页

- **WHEN** 用户在 tip 命中盒内按下并横向拖动
- **THEN** PageView MUST NOT 切换页面
- **AND** tip MUST 可被拖动（expanded/collapsed）或按既有 docked 规则处理

#### Scenario: tip 外仍可滑页

- **WHEN** 用户在 tip 命中盒外的喂养页区域横滑
- **THEN** PageView MUST 仍可切页（未被 tip 全屏吞手势）

### Requirement: Input mode dock hit target MUST block PageView on pointer down

While a pointer is down within the home input mode dock’s hittable target (edge semicircle/full circle or floating circle, including the expanded hit pad), the client MUST prevent the home PageView from horizontal page changes until the pointer is released or cancelled, even if the gesture is only a tap to cycle modes and never exceeds drag slop. 输入模式 dock 热区内指针按下期间，客户端 **必须** 阻止 PageView 横滑，直至抬起或取消；即使仅为点按切换模式（未超过拖动 slop）亦然。

#### Scenario: 按住模式球横滑不切页

- **WHEN** 用户在模式切换球热区内按下并横向拖动（含未达拖动吸附前的滑动）
- **THEN** PageView MUST NOT 切换页面

#### Scenario: 点按模式球仍可切换

- **WHEN** 用户在模式球热区内点按松开（判定为点击）
- **THEN** 客户端 MUST 仍按既有规则切换/展开输入模式
- **AND** 指针抬起后 PageView 横滑 MUST 恢复可用

### Requirement: Tap top badge MUST collapse tip under the icon

When the tip is expanded, a tap on the top badge (pointer up without exceeding drag slop) MUST play a shrink animation that collapses the card under/into the badge and leave a floating full circle (collapsed) at the current position, without dismissing tip content. 展开态点击顶标（未超过拖动 slop）**必须** 播放缩小动画，将卡片收到图标下/并入圆，在当前位置留下浮空全圆（collapsed），**不得** dismiss 内容。

#### Scenario: 点标折叠

- **WHEN** tip expanded
- **AND** 用户点击顶标（非拖动）
- **THEN** 卡片与下方按钮 MUST 以动画收起
- **AND** 界面 MUST 保留可点的胖宝圆（collapsed）
- **AND** tip 文本状态 MUST 仍保留（非 idle）

#### Scenario: 点圆展开

- **WHEN** tip collapsed
- **AND** 用户点击浮空圆
- **THEN** tip MUST 恢复 expanded（含卡片与按钮）
