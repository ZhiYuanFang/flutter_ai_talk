## ADDED Requirements

### Requirement: 预测页横屏 MUST 使用左身份栏与右多列瀑布

When the smart prediction page is displayed in `Orientation.landscape`, the client MUST lay out a left identity rail and a right event-card region. The left rail MUST show only the baby display nickname and, when age is shown, the age text, using vertical (stacked per-character) typography. The left rail MUST NOT show the baby avatar, theme palette control, or layout-toggle control. The right region MUST show the compact waterfall of prediction event cards and MUST NOT show the care-alert panel, swipe-guide card, next-three-hours panel, or bottom tip. Landscape waterfall column count MUST be **three** when `MediaQuery` shortest side is below 600 logical pixels, and **five** when shortest side is at least 600 (tablet-class). In landscape the client MUST force compact/waterfall rendering even if the persisted layout preference is list, and MUST NOT expose the list/grid toggle. Portrait orientation MUST keep the existing top identity chrome, tools, care/guide/timeline behavior, and two-column waterfall (when compact).

智能预测页处于 `Orientation.landscape` 时，客户端 **必须** 采用左身份栏 + 右事件区布局。左栏 **必须** 仅展示宝宝展示昵称，并在展示月龄时展示月龄文案，且采用竖排（逐字纵向）排版；左栏 **不得** 展示宝宝头像、调色盘或布局切换控件。右区 **必须** 以 compact 瀑布展示预测事件卡，且 **不得** 展示值得留意、滑动引导大卡、接下来3小时或底 tip。横屏瀑布列数：当 `MediaQuery` 最短边 **小于** 600 逻辑像素时 **必须** 为 **三列**；最短边 **大于等于** 600（平板档）时 **必须** 为 **五列**。横屏 **必须** 强制按 compact/瀑布渲染（即便本地偏好为列表），且 **不得** 露出列表/瀑布切换入口。竖屏 **必须** 保持既有顶栏身份与工具、留意/引导/时间线行为，以及 compact 时的双列瀑布。

#### Scenario: 手机横屏三列瀑布

- **WHEN** 用户在横屏打开智能预测页且最短边 < 600
- **THEN** UI MUST 左侧为竖排昵称（及适用时的月龄）
- **AND** 右侧 MUST 为三列事件瀑布
- **AND** MUST NOT 展示头像、调色盘、布局切换

#### Scenario: 平板横屏五列瀑布

- **WHEN** 用户在横屏打开智能预测页且最短边 ≥ 600
- **THEN** 右侧 MUST 为五列事件瀑布
- **AND** MUST NOT 展示头像、调色盘、布局切换

#### Scenario: 横屏隐藏留意与引导 chrome

- **WHEN** 用户在横屏查看智能预测页（含未登录/未绑定冷态）
- **THEN** UI MUST NOT 展示值得留意面板
- **AND** MUST NOT 展示滑动引导大卡
- **AND** MUST NOT 展示接下来3小时面板

#### Scenario: 横屏强制瀑布且无切换入口

- **WHEN** 本地布局偏好为纵向列表且设备为横屏
- **THEN** 预测页 MUST 仍渲染横屏瀑布（三列或五列按最短边）
- **AND** MUST NOT 展示切换为列表/瀑布的控件

#### Scenario: 竖屏保持双列与顶栏

- **WHEN** 用户在竖屏打开智能预测页且偏好为 compact
- **THEN** UI MUST 保持顶栏身份与工具行
- **AND** 事件卡 MUST 为双列瀑布（非因本需求改为三/五列）
