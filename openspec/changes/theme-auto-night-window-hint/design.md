## Context

自动夜空窗口已由 `AppThemeSchedule.isNightWindow` 固定为本地 `h >= 19 || h < 5`（即 19:00–05:00），基线 `app-theme-schedule` 已描述该行为。公用主题 Sheet（`theme_palette_sheet.dart`）仅展示「自动夜空」标签与 Switch，用户无法从 UI 得知时段。

## Goals / Non-Goals

**Goals:**

- 在「自动夜空」标签下方常驻展示 `19:00–05:00`。
- 与现有 hint 色阶协调（更小、更淡），不破坏顶栏 Row 对齐。

**Non-Goals:**

- 不提供时段编辑、时区选择或日出日落自适应。
- 不改调度公式、默认开关状态或持久化键。
- 不强制抽取小时常量（可选；实现可硬编码文案）。

## Decisions

### 1. 文案与可见性

- 固定文案：`19:00–05:00`（与注释/spec 一致，窄屏友好）。
- **始终显示**（开关关时也显示），避免「开了才看到几点」的发现成本。

### 2. 布局

将右侧由单行 `Text + Switch` 改为：

```
[主题]     Column(end): 「自动夜空」     Switch
                      「19:00–05:00」
```

`Row` 的 `crossAxisAlignment: center`，使 Switch 相对两行文案垂直居中。

### 3. 单一真相（可选）

优先最小改动：Sheet 内硬编码文案。若同 PR 顺手抽 `kNightScheduleStartHour` / `kNightScheduleEndHour` 并用于 `isNightWindow` 与展示格式化，可减少日后漂移；非验收硬性要求。

## Risks / Trade-offs

- [文案与逻辑漂移] → 验收以调度窗口为准；改小时时须同步文案（或抽常量）。
- [右侧换行/挤压] → 文案极短；若极窄屏可接受换行，不引入自适应省略。
