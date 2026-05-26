## Context

- **现状**：`BabyProfileEditScreen` 包一层 `ListView` + `BabyProfileEditor` 使用 `Card`、`TextFormField`、`SegmentedButton`、`ListTile` + `showDatePicker`。
- **参考稿**：暖黄渐变背景、白色大圆角主卡、内凹输入、性别双色胶囊、「选择日期」区；装饰云朵/星星（可用 Icon 或轻量 Asset，非必须 1:1 贴图）。
- **约束**：保存仍走 `SettingsRepository.saveBaby`；生日范围 `2000-01-01`～今天；昵称非空；性别变更仍触发 `babySexProvider` / `persistCachedBabySex`。
- **项目内先例**：历史/趋势使用 `CupertinoDatePicker` / `CupertinoPicker`；主页玻璃 Sheet 与设置页 Material 并存——本页采用**独立黏土浅色主题**，不强制套深色 `HistoryEditGlassPanel`，避免与参考稿冲突。

## Goals / Non-Goals

**Goals:**

- 编辑页布局与参考图信息架构一致：昵称 → 性别 → 生日 → 操作按钮。
- 黏土拟态：高圆角、外凸卡片阴影、内凹字段（浅灰底 + 内阴影近似）。
- 生日 **滚轮**选择（`CupertinoDatePickerMode.date`），禁止 Material 日历弹窗。
- 经典/夜空等全局主题下，本页仍保持可读（黏土卡片自包含配色，少依赖 `onShell`）。

**Non-Goals:**

- 不重做 `BabyBindScreen` 创建宝宝流程（可后续复用组件）。
- 不新增网络接口或字段。
- 不要求与主页深色玻璃趋势页视觉统一。

## Decisions

1. **组件拆分**  
   新增 `baby_profile_clay_theme.dart`（色板、圆角、阴影常量）+ `clay_form_widgets.dart`（`ClayProfileCard`、`ClayInsetField`、`ClayChoiceChip`）。`BabyProfileEditor` 只编排业务状态。  
   **备选**：全部写在 editor 单文件 — 否决，不利于绑定页复用。

2. **生日交互**  
   **决定**：卡片内**内嵌** `CupertinoDatePicker`（date 模式，高度约 160–180），上方显示当前 `yyyy-MM-dd`；用户直接滚轮改日期。  
   **备选 A**：点击「选择日期」条再弹 Sheet — 与参考图条形态一致但多一步；若内嵌高度不足可改为 tap → `showBabyBirthdayWheelSheet`（黏土/浅色底，非 Material）。  
   **默认实现内嵌**；小屏用 `SingleChildScrollView` 防溢出。

3. **性别**  
   参考图仅「男」「女」两枚胶囊；保留 `BabySex.unknown` 为第三枚小字按钮或「暂不选择」，避免破坏现有数据。选中态：男=浅蓝底、女=浅粉底。

4. **屏幕背景**  
   `Scaffold` 使用固定暖色 `LinearGradient`（如 `#FFF6E8` → `#FFE8D6`），与 `AppVisualTokens` 解耦。AppBar 保持简洁返回 + 标题「编辑宝宝信息」。

5. **图标**  
   昵称区左侧 `Icons.child_care` 或奶瓶类 icon 代替贴图；标签旁 `Icons.cloud` / `Icons.star` 装饰 — 无新 asset 亦可。

## Risks / Trade-offs

- **[Risk] 黏土页与全局深色主题反差大** → 仅作用于设置子路由；卡片内自洽浅色对比度。  
- **[Risk] 双滚轮日期 + 键盘昵称导致小屏溢出** → `ListView` + 压缩 picker 高度。  
- **[Risk] `CupertinoDatePicker` 在 Android 上风格偏 iOS** → 产品已接受（历史时间滚轮同款）。

## Migration Plan

1. 实现黏土组件与 editor 重构。  
2. 手工：改昵称/性别/生日保存、取消恢复、边界日期。  
3. `dart analyze` 相关文件。无数据迁移。

## Open Questions

- 是否在 v1 同步把 `BabyBindScreen` 生日改为滚轮（当前 **否**，Non-Goal）。
