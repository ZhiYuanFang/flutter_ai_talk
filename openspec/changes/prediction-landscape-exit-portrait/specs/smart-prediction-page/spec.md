## ADDED Requirements

### Requirement: Landscape density rail MUST provide exit-to-portrait control

When the smart prediction page is displayed in `Orientation.landscape`, the right density column MUST show a compact control **above** the vertical hint「拖动调整大小」. When the user activates this control, the client MUST switch the UI to portrait and MUST restore full device orientation freedom by calling `SystemChrome.setPreferredOrientations(DeviceOrientation.values)`. The control MUST NOT overlap or block vertical dragging on the density track below. Landscape immersive UI and wakelock MUST release through existing landscape lifecycle when orientation returns to portrait.

横屏智能预测页右密度栏 **必须** 在竖排提示「拖动调整大小」**上方** 提供返回竖屏控件。用户触发后 **必须** 切回竖屏，并 **必须** 通过 `SystemChrome.setPreferredOrientations(DeviceOrientation.values)` **恢复全方向**旋转；**不得** 阻挡下方密度轨纵向拖动。回竖屏后横屏沉浸/常亮 **必须** 经现有横屏生命周期释放。

#### Scenario: 点击返回竖屏

- **WHEN** 用户在横屏预测页点击右栏返回竖屏控件
- **THEN** 页面 **MUST** 以竖屏布局展示
- **AND** 系统 **MUST** 允许 `DeviceOrientation.values` 中的全部方向（恢复全方向）

#### Scenario: 返回竖屏不阻挡密度轨

- **WHEN** 用户在横屏查看右密度栏
- **THEN** 返回竖屏控件 **MUST** 位于密度轨与竖排提示之上
- **AND** 密度轨 **MUST** 仍可纵向拖动调整列数

### Requirement: Cast-mode dialog MUST describe exit affordance

The portrait cast-mode confirmation dialog on the smart prediction page MUST NOT state that the user must restart the app to exit landscape. It MUST inform the user that landscape can be exited via the return-to-portrait control on the landscape right rail.

竖屏投屏确认对话框 **不得** 再写「需重启应用才能退出」；**必须** 说明可在横屏右栏使用返回竖屏控件退出。

#### Scenario: 投屏对话框可发现退出方式

- **WHEN** 用户在竖屏打开投屏确认对话框
- **THEN** 文案 **MUST** 提及横屏右栏返回竖屏入口
- **AND** 文案 **MUST NOT** 要求重启应用才能退出横屏
