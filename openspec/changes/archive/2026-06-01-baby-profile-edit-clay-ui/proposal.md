## Why

「编辑宝宝信息」当前为默认 Material 卡片 + `OutlineInputBorder` + `SegmentedButton` + `showDatePicker`，与产品参考稿的柔和黏土拟态（圆角、内凹输入、粉蓝性别胶囊、装饰性图标）差距大，且生日选择与趋势/历史编辑已采用的滚轮交互不一致。需要在不改变保存契约的前提下统一视觉与日期选择体验。

## What Changes

- **编辑页视觉**：`BabyProfileEditScreen` / `BabyProfileEditor` 采用参考图结构的黏土拟态主卡片（大圆角、双层阴影、暖色渐变底、分区标签与装饰图标）。
- **昵称**：内凹胶囊输入条 + 占位「请输入昵称」；保留非空校验。
- **性别**：粉/蓝双色可选胶囊（男/女）；保留「未填」能力（弱化展示或第三项），保存逻辑不变。
- **生日**：移除 Material `showDatePicker`；改为 **Cupertino 日期滚轮**（内嵌于卡片或玻璃/黏土底 Sheet，与项目内时间滚轮一致）。
- **操作区**：保存/取消按钮样式与卡片协调；`settingsRepository.saveBaby`、主题性别联动等行为不变。
- **不改动**：`BabyBindScreen` 创建流程、API 字段、校验规则（2000–今天）除交互形态外保持不变。

## Capabilities

### New Capabilities

- `baby-profile-clay-editor-ui`：编辑宝宝信息页的黏土拟态布局、字段样式与生日滚轮选择交互。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线）行为层面延续 `pangbao-m2-editing-trends` 中 `baby-profile-editing` 的保存/校验语义，仅 UI 与生日控件形态变更，由新能力规格覆盖可见行为。

## Impact

- Flutter：`app/lib/ui/baby_profile_editor.dart`、`baby_profile_edit_screen.dart`；新增可复用黏土组件（如 `app/lib/ui/widgets/clay_*` 或 `baby_profile_clay_theme.dart`）。
- 可参考：`home_history_time_wheel.dart`、`trends_date_range_glass_sheet.dart` 的滚轮与 Sheet 模式。
- 无后端/API 变更。
