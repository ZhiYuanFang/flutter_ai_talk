## Context

`smart-prediction-appointment-accuracy-ux` 在 `copyWith(primary:)` 后用 `estimateBrightnessForColor` 二选一白/黑。深色壳可读；浅色柔和 primary 上纯黑字发沉。记录 sheet 确认钮底为事件 `accent`，却用了主题 `AppColor.onPrimary`，浅色下黑字压彩底更丑。

## Goals / Non-Goals

**Goals:**

- 主题 `onPrimary` 与覆盖后的 `primary` 按 Material `ColorScheme.fromSeed` 成对。
- accent 底实心钮前景相对 accent 成对。
- 深色壳保存/确认仍可读。

**Non-Goals:**

- 改 VisualBundle / 预设色盘本身。
- 非实心主钮（描边、文字钮）全面换色。

## Decisions

1. **主题配对**  
   ```dart
   final paired = ColorScheme.fromSeed(
     seedColor: primaryColor,
     brightness: tokens.isDarkShell ? Brightness.dark : Brightness.light,
   );
   scheme = ColorScheme.fromSeed(...).copyWith(
     primary: primaryColor,
     onPrimary: paired.onPrimary,
     ...
   );
   ```  
   保留精确品牌 `primary`；`onPrimary` 跟 Material 对 seed≈primary 的建议，禁止二元黑白。

2. **accent 钮**  
   记录确认等：`foregroundColor` 取 `ColorScheme.fromSeed(seedColor: accent, brightness: Theme.brightness).onPrimary`（或抽小 helper）。禁止用主题 `AppColor.onPrimary` 当 accent 底前景。

3. **primary 底钮**  
   历史保存、预约确认等 `backgroundColor: scheme.primary` 继续 `AppColor.onPrimary` / `scheme.onPrimary`。

## Risks / Trade-offs

- [fromSeed(onPrimary) 与精确 primary 微差] → 可接受；优于纯黑/纯白。  
- [每帧 fromSeed(accent)] → 仅 build 确认钮时算一次，可忽略；若重复可缓存。

## Migration Plan

1. 改 `buildAppThemeFromBundle`；改 `event_record_sheet` accent 前景。  
2. 浅色 / 深色各看保存与记录确认。  
3. 回滚：恢复二元估计（不推荐）。

## Open Questions

- 无。
