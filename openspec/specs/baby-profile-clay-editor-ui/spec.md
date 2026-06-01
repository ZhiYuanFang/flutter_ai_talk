## ADDED Requirements

### Requirement: Clay-style baby profile edit layout

The baby profile edit screen SHALL present nickname, sex, and birth date on a single large rounded card with soft elevation and a warm gradient page background, visually aligned with the product claymorphism reference (inset fields, pill sex choices, decorative section labels).

编辑宝宝信息页 MUST 使用黏土拟态主卡片承载表单：大圆角、柔和外阴影、页面暖色渐变底；昵称/性别/生日分区标签清晰；不得再使用默认 Material `Card` + `OutlineInputBorder` 作为主视觉。

#### Scenario: Open edit screen

- **WHEN** 用户从设置进入「编辑宝宝信息」且宝宝资料加载成功
- **THEN** 页面 MUST 展示黏土风格主卡片，包含昵称、性别、生日三个区块及保存/取消操作

#### Scenario: Nickname inset field

- **WHEN** 用户查看昵称区
- **THEN** MUST 展示内凹圆角输入条与「请输入昵称」类占位；保存时仍 MUST 校验非空

### Requirement: Sex selection with pill chips

The system SHALL let users choose baby sex using two primary pill controls for male and female, and SHALL still support selecting unknown without using a Material `SegmentedButton` as the primary control.

性别 MUST 以双色胶囊（男/女）为主交互；MUST 仍可保存 `BabySex.unknown`（例如「暂不选择」）；不得再以 Material 分段按钮作为唯一性别控件。

#### Scenario: Select male or female

- **WHEN** 用户点选「男」或「女」胶囊
- **THEN** 保存前内部状态 MUST 更新为对应 `BabySex`，选中态 MUST 有视觉区分（如蓝/粉底）

#### Scenario: Theme updates after sex save

- **WHEN** 用户修改性别并保存成功且未覆盖自定义主题逻辑
- **THEN** 行为 MUST 与既有规则一致：按新性别更新默认主题色

### Requirement: Birthday wheel picker

The system SHALL use a Cupertino-style date wheel for birth date selection on the edit screen and MUST NOT use Material `showDatePicker` as the primary birthday UI.

生日 MUST 通过 **Cupertino 日期滚轮**选择（内嵌于编辑卡片或等价浅色 Sheet）；MUST NOT 以 Material 日历对话框作为唯一入口。可选范围 MUST 仍为 2000-01-01 至今天（本地自然日）。

#### Scenario: Adjust birth date with wheel

- **WHEN** 用户在生日滚轮上调整年/月/日
- **THEN** 表单内展示的日期 MUST 实时更新，且 MUST 落在合法范围内

#### Scenario: Save with wheel-selected date

- **WHEN** 用户滚轮选定生日后点击保存
- **THEN** `BabyProfile.birthDate` MUST 以所选本地自然日写入仓库，与改前保存契约一致

#### Scenario: No material date picker on edit screen

- **WHEN** 用户在编辑宝宝信息页操作生日
- **THEN** 系统 MUST NOT 弹出 Material `showDatePicker` 作为默认交互

### Requirement: Preserve save and cancel semantics

The system SHALL keep existing save, cancel, validation, and toast behavior for baby profile editing aside from visual and birthday control changes.

除 UI 与生日控件外，保存/取消/校验/Toast MUST 与变更前一致：`saveBaby`、失败提示、取消恢复上次加载数据。

#### Scenario: Cancel restores loaded data

- **WHEN** 用户修改表单后点击取消
- **THEN** MUST 恢复为进入页面时加载的昵称、性别、生日，且不调用保存接口
