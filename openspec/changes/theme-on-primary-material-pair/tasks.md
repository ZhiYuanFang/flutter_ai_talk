## 1. 主题 onPrimary

- [x] 1.1 `buildAppThemeFromBundle`：用 `ColorScheme.fromSeed(seedColor: primaryColor, brightness: 壳)` 的 `onPrimary` 覆盖；去掉 estimate→白/黑

## 2. accent 底确认钮

- [x] 2.1 `event_record_sheet` 确认钮：前景相对 `accent` fromSeed 成对，不用主题 `AppColor.onPrimary`
- [x] 2.2 快扫其它 `backgroundColor: accent` + 主题 onPrimary 的实心钮，同类则改

## 3. 验收

- [ ] 3.1 浅色壳：保存 / 记录确认观感正常；深色壳：保存仍可读
