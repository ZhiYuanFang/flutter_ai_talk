## ADDED Requirements

### Requirement: 缺省 logo 与色调

The UI SHALL show a bundled placeholder image when an event has no local logo file, and SHALL use the app primary theme color when an event has no parseable brand color. 当事件无本地 logo 文件时，界面必须使用应用内**占位图**资源；当事件无有效 `color` 时，界面必须使用当前上下文的**主色调**（`Theme.colorScheme.primary`，与 Material 主色一致），**不得**使用固定黑色作为缺省色。

#### Scenario: 无 logo

- **WHEN** 某事件无 `localLogoPath` 且 `logo` URL 为空或不可用
- **THEN** 所有展示位必须显示同一占位图，且尺寸符合各场景约束

#### Scenario: 无色调

- **WHEN** 某事件的 `color` 缺失或解析失败
- **THEN** 该事件相关强调色（圆点、文字、图表、chip 边框等）必须使用 `colorScheme.primary`

#### Scenario: 有品牌色

- **WHEN** 某事件的 `color` 解析成功
- **THEN** 必须使用解析后的 `Color` 作为该事件在该场景下的强调色

### Requirement: 主页历史时间轴展示

The home history timeline row MUST display the event logo and brand color for each record. 主页历史时间轴每一行必须在事件名附近展示该事件的 **logo**（约 16–20 逻辑像素），并将时间轴圆点或事件名强调色设为该事件品牌色（无色调时用主色）；行高仍须保持紧凑（约 34px 量级），不得因 logo 撑开多行。

#### Scenario: 有品牌资源的历史条

- **WHEN** 用户查看主页历史列表且该条 `eventId` 在目录中
- **THEN** 行内必须可见 logo 与品牌色强调

#### Scenario: 点击进详情

- **WHEN** 用户点击时间轴行
- **THEN** 导航至历史详情时行为与变更前一致，详情页须继续展示同一事件品牌资源

### Requirement: 今日汇总展示

The home today summary chips MUST show each aggregated event with its logo and brand color. 主页「今日」汇总区每个 chip 必须在文案旁展示对应事件的 **logo** 与品牌色（浅底或边框使用品牌色 alpha）；聚合必须按 **`eventId`** 与事件目录对齐，不得仅按易重名的 `eventName` 字符串合并不同事件。

#### Scenario: 今日有多类事件

- **WHEN** 当日历史含多个不同 `eventId` 的有效记录
- **THEN** 今日区必须分别展示各事件的 chip，且各 chip 视觉可区分

### Requirement: 历史详情展示

The history detail screen MUST show the event logo and brand color in both view and edit modes. 历史详情页在**预览**与**编辑**模式下，必须在事件名区域展示该记录的 **logo** 与品牌色（无资源时用占位与主色）。

#### Scenario: 打开详情

- **WHEN** 用户从主页进入某条历史详情
- **THEN** 标题/事件名区域必须显示 logo 与品牌色，且与主页列表所用目录一致

### Requirement: 趋势中心展示

The trends screen MUST use the global event catalog for the event picker and apply the selected event's logo and color to the picker and chart emphasis. 趋势中心事件下拉（或等效选择器）的每一项必须展示 **logo** 与事件名；当前选中事件的折线/柱图强调色必须使用其品牌色（无色调时用主色）。目录数据必须来自全局事件目录，不得单独维护仅含 `title` 的孤立列表。

#### Scenario: 选择事件后看图

- **WHEN** 用户在趋势页选择某一事件并加载 `piece` 数据
- **THEN** 图表主色必须与该事件品牌色一致（或主色缺省）

#### Scenario: 目录为空

- **WHEN** 全局目录为空且接口未返回列表
- **THEN** 必须保留现有空态提示，不得崩溃
