## Why

深色壳下覆盖 `primary` 后补了 `onPrimary`，可读性已恢复；但实现用「偏暗→白 / 偏亮→纯黑」二元估计，浅色主题（尤其柔和性别主色）字色发沉发丑。应用 Material 成对色，而不是手写黑白。

## What Changes

- `buildAppThemeFromBundle`：覆盖 `primary` 时，`onPrimary` 取自以该 `primary` 为 seed 的 `ColorScheme.fromSeed(...).onPrimary`（同壳 brightness），**不得**再用 `estimateBrightness → Colors.white/black`。
- 以事件 `accent` 为底的实心确认钮（如统一记录 sheet）：前景 MUST 相对 **accent** 成对（可用同法或局部 fromSeed），**不得**误用仅跟主题 primary 的 `AppColor.onPrimary`。
- 以 `scheme.primary` 为底的钮（如历史保存、预约确认）继续用 `colorScheme.onPrimary` / `AppColor.onPrimary`。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `theme-on-primary`：修正配对算法（Material onPrimary）；明确 accent 填充钮的前景规则。

## Impact

- 主要：`app_theme_scope.dart`、`event_record_sheet.dart`；其它 accent 底 FilledButton 若同类一并扫一眼。
- 关联回归：`smart-prediction-appointment-accuracy-ux` 的 theme-on-primary。
- 无 API / **BREAKING** 契约变更。
