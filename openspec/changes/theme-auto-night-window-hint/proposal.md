## Why

公用主题 Sheet 上的「自动夜空」只有开关文案，用户看不到生效时段。调度已固定为本地时间 19:00–05:00，需要在开关旁常驻展示该窗口，降低「开了也不知道何时变夜空」的困惑。

## What Changes

- 在主题调色 Sheet 的「自动夜空」标签**下方**增加始终可见的小字提示，文案固定为 `19:00–05:00`（与 `AppThemeSchedule` / 基线调度窗口一致）。
- 开关开闭均显示该小字；不引入可编辑时段 UI。
- 调度逻辑、持久化键与窗口边界不变。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `app-theme-customization`：自动夜空开关旁 MUST 常驻展示调度窗口文案 `19:00–05:00`。

## Impact

- UI：`app/lib/ui/theme_palette_sheet.dart`（「自动夜空」行布局：标题 + 小字 + Switch）。
- 可选：若抽出小时常量，触及 `app/lib/theme/app_theme_schedule.dart`（非必须；文案可与现有魔法数对齐硬编码）。
- 不影响：`app-theme-schedule` 行为、设置页（主题入口已迁至 Sheet）、Android/原生、WebSocket、日志白名单。
