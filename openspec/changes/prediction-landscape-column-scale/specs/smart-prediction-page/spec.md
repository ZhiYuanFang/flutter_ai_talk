## MODIFIED Requirements

### Requirement: 预测页横屏 MUST 使用左身份栏与右多列瀑布

When the smart prediction page is displayed in `Orientation.landscape`, the client MUST lay out a left identity rail and a right event-card region. The left rail MUST show the baby display nickname and, when age is shown, the age text, using vertical typography; when vertical space is insufficient, the client MUST truncate the age text from the tail (and MAY truncate the nickname from the tail) rather than overflowing the rail. The client MUST lay out landscape as **three horizontal regions**: left identity rail, **center** compact waterfall (`Expanded`), and a **dedicated right column** for the density control. Event cards MUST NOT render under or overlap the density column. The right column MUST show vertical hint text **「拖动调整大小」** stacked above the track using the same vertical typography style as the identity rail. The track MUST extend from below the hint to the bottom safe area (dynamic height, not a fixed short track). The user MUST adjust column count by **dragging** on the track: **up** MUST decrease columns (larger cards), **down** MUST increase columns (smaller cards). The UI MUST NOT display the numeric column count. The track MUST clamp column count to the inclusive range **3–7** and MUST persist locally. When no persisted column count exists, the default MUST be **3** when `MediaQuery` shortest side is below 600 logical pixels and **5** when shortest side is at least 600. The center region MUST render the compact waterfall using the effective column count. Portrait orientation MUST keep two-column waterfall when compact and MUST NOT show the landscape density track.

智能预测页横屏时 **必须** 左身份栏 + 中 compact 瀑布 + 右密度轨三栏布局；事件卡 **不得** 盖住右缘拖动区。左栏 **必须** 竖排昵称与月龄；高度不足时 **必须** 从尾部省略月龄（**可** 省略昵称尾部），**不得** 越界。右栏 **必须** 展示纵向密度轨（真拖）：轨上方 **必须** 竖排提示「拖动调整大小」；轨 **必须** 自提示下方拉满至屏底安全区（动态高度）；**向上** 减少列数（大卡）、**向下** 增加列数（小卡）；**不得** 展示列数数字；范围 **3–7** 并持久化；无存档时手机默认 **3** 列、平板默认 **5** 列。竖屏 **不得** 展示该控件。

#### Scenario: 手机横屏默认三列

- **WHEN** 用户在横屏打开预测页、最短边 < 600 且无持久化列数
- **THEN** 瀑布 MUST 为三列

#### Scenario: 平板横屏默认五列

- **WHEN** 用户在横屏打开预测页、最短边 ≥ 600 且无持久化列数
- **THEN** 瀑布 MUST 为五列

#### Scenario: 密度轨拖动增减列数

- **WHEN** 用户在密度轨上向下拖至更大档位且当前列数 < 7
- **THEN** 列数 MUST 增加并重排瀑布
- **WHEN** 用户在密度轨上向上拖至更小档位且当前列数 > 3
- **THEN** 列数 MUST 减少

#### Scenario: 密度轨不展示数字

- **WHEN** 用户在横屏查看右缘密度轨
- **THEN** UI MUST NOT 展示列数阿拉伯数字标签

#### Scenario: 右缘密度轨竖排提示与满高轨道

- **WHEN** 用户在横屏查看智能预测页
- **THEN** 右缘 MUST 在密度轨上方竖排展示「拖动调整大小」
- **AND** 密度轨 MUST 自提示下方延伸至屏底安全区

#### Scenario: 三栏布局事件不遮挡密度轨

- **WHEN** 用户在横屏查看智能预测页且存在事件卡
- **THEN** 布局 MUST 为左身份栏、中瀑布、右密度轨
- **AND** 事件卡 MUST NOT 覆盖或绘制于右密度轨列之上

## ADDED Requirements

### Requirement: Landscape compact cards MUST scale with cell width

When rendering compact prediction cards in landscape, the client MUST compute a scale factor from the current waterfall cell width relative to the reference cell width at the device-class baseline column count (3 for phone, 5 for tablet). Title font size, auxiliary copy, countdown numerals, title and hero event logos, forecast switch scale, card padding, card border radius, and inter-card gaps MUST multiply the existing compact baseline constants by this scale so that cards fit their column without overflow. Hero logo above the countdown MUST shrink with scale and MUST NOT be replaced solely due to high column count.

横屏 compact 预测卡 **必须** 按当前单元格宽度相对设备档基准列宽计算 scale，并将标题字号、辅助文案、倒计时数字、title/hero logo、推演 Switch 缩放、卡内边距、**卡片圆角**与卡间距在既有 compact 基准上乘以 scale，使各列数下内容可完整展示；倒计时上方 hero logo **必须** 随 scale 缩小，**不得** 仅因列数多而强制改为侧 logo。

#### Scenario: 七列仍完整展示

- **WHEN** 用户将横屏列数设为 7
- **THEN** 事件卡 MUST NOT 因固定字号/logo 尺寸而水平溢出列宽

#### Scenario: 七列圆角随 scale 缩小

- **WHEN** 用户将横屏列数设为 7
- **THEN** 卡片圆角 MUST 随 scale 缩小（基准 18×scale）
- **AND** MUST NOT 保持固定 18dp 导致小卡相对圆角过大

#### Scenario: 基准列数 scale 为 1

- **WHEN** 有效列数等于设备档默认（手机 3 / 平板 5）
- **THEN** scale MUST 约为 1（与变更前视觉一致）

### Requirement: Compact forecast toggle header MUST align title with switch

When rendering a compact prediction event card header, the client MUST lay out two rows. Row 1 MUST vertically center-align the event title with the forecast switch only. The switch layout slot MUST be `52 × switchScale` wide (using `FittedBox`, not layout-inflating `Transform.scale`). Row 2 MUST show overdue relative copy (when present) and the forecast toggle caption on the **same line**, right-aligned so the **right edge** of the caption row aligns with the switch right edge. Both texts MUST use a single line with tail ellipsis and MUST NOT wrap. The client MUST NOT use magic vertical offsets (`toggleLabelOffsetY`) to align toggle copy.

compact 预测卡 header **必须** 两行：第 1 行事件名 **必须** 仅与推演 Switch 纵向对齐；Switch 占位 **必须** 为 `52×switchScale`（`FittedBox`，**不得** 用占满 intrinsic 的 `Transform.scale`）。第 2 行 **必须** 将超时相对文案（若有）与开关说明「关闭/开启{事件名}预测」**同一行**展示，整段右对齐且 **右缘 MUST 与 Switch 右缘对齐**；两段 **必须** 单行尾部省略、**不得** 换行；**不得** 再用 magic 纵向偏移对齐开关文案。

#### Scenario: 列数变化时开关文案仍对齐 Switch

- **WHEN** 用户调整横屏列数导致卡片变窄或变宽
- **THEN** 开关说明文案右缘 MUST 仍与 Switch 右缘对齐
- **AND** 事件名 MUST 仍与 Switch 纵向居中对齐

#### Scenario: 超时与开关文案同一行

- **WHEN** compact 卡片展示超时相对文案且展示开关说明
- **THEN** 两段文案 MUST 位于同一行
- **AND** 整行 MUST 右对齐于 Switch 右缘

#### Scenario: 七列文案单行省略

- **WHEN** 用户在 7 列横屏查看事件卡且文案过长
- **THEN** 超时文案与开关说明 MUST 单行展示且 MUST 尾部省略

### Requirement: Landscape identity rail MUST show baby avatar above nickname

When the smart prediction page is in landscape, the left identity rail MUST show the baby avatar above the vertically stacked nickname. The avatar MUST use the same `BabyAvatar` component and baby display inputs as portrait (`babyId`, `sex`). The avatar MAY be tappable to open settings when the portrait header provides the same affordance.

横屏左身份栏 **必须** 在竖排昵称上方展示宝宝头像，使用与竖屏一致的 `BabyAvatar` 与 `babyId`/`sex` 入参；**可** 与竖屏顶栏一样支持点按进入设置。

#### Scenario: 横屏左栏头像在昵称上

- **WHEN** 用户在横屏查看智能预测页
- **THEN** 左栏 MUST 在竖排昵称上方展示宝宝头像
