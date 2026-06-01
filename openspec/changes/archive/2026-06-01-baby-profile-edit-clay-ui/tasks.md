## 1. 黏土主题与基础组件

- [x] 1.1 新增 `baby_profile_clay_theme.dart`：暖色渐变、卡片圆角、外阴影/内凹色常量
- [x] 1.2 新增 `clay_form_widgets.dart`：`ClayProfileCard`、`ClayInsetField`、分区标签（含可选装饰 Icon）

## 2. 表单字段

- [x] 2.1 昵称：内凹输入 + 占位「请输入昵称」+ 非空校验
- [x] 2.2 性别：男/女双色胶囊 +「暂不选择」对应 `BabySex.unknown`；移除 `SegmentedButton`
- [x] 2.3 生日：内嵌 `CupertinoDatePicker`（date，`2000-01-01`～今天）；移除 `showDatePicker`

## 3. 页面集成

- [x] 3.1 重构 `BabyProfileEditor` 使用黏土组件；保留保存/取消/Toast/仓库逻辑
- [x] 3.2 `BabyProfileEditScreen`：渐变 Scaffold 背景 + `ListView` 防溢出

## 4. 验证

- [x] 4.1 手工：改昵称/性别/生日保存、取消恢复、边界日期、主题随性别
- [x] 4.2 `dart analyze` 宝宝编辑相关文件无新增告警

## 5. 主题背景

- [x] 5.1 页面背景与 AppBar 前景随 `AppVisualTokens.shellColor` / `onShell` 变化
