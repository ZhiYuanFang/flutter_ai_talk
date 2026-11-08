## ADDED Requirements

### Requirement: Theme SHALL derive onPrimary from Material pairing of primary

When the app builds `ColorScheme` and overrides `primary`, it MUST set `onPrimary` to the `onPrimary` produced by `ColorScheme.fromSeed` with `seedColor` equal to that primary and the same shell brightness (light vs dark shell). The client MUST NOT assign `onPrimary` solely by mapping `estimateBrightnessForColor(primary)` to hardcoded `Colors.white` or `Colors.black`. 覆盖 primary 时 MUST 用 Material fromSeed 成对的 onPrimary；MUST NOT 仅用亮暗估计映射为纯白/纯黑。

#### Scenario: Light shell soft primary not pure black label

- **WHEN** 浅色壳主题下 `primary` 为柔和品牌色且构建 Theme
- **THEN** `colorScheme.onPrimary` MUST 来自对该 primary 的 fromSeed 配对，MUST NOT 为强制的 `Colors.black`

#### Scenario: Dark shell save remains readable

- **WHEN** 深色壳主题下打开历史编辑 sheet 点「保存」（底为 primary）
- **THEN** 按钮文字色 MUST 为成对的 onPrimary 且可读

### Requirement: Accent-filled solid buttons SHALL pair label to accent fill

When a solid confirm button uses an event (or other) `accent` as `backgroundColor` rather than `colorScheme.primary`, its label foreground MUST contrast with that accent fill (e.g. `ColorScheme.fromSeed(seedColor: accent, brightness: current).onPrimary`). The client MUST NOT use theme `AppColor.onPrimary` / `colorScheme.onPrimary` as the label color for such accent-filled buttons. 以 accent 为底的实心确认钮字色 MUST 相对 accent 成对；MUST NOT 误用主题 primary 的 onPrimary。

#### Scenario: Record sheet confirm on accent

- **WHEN** 统一记录 sheet 主确认钮底色为事件 accent
- **THEN** 前景 MUST 相对该 accent 成对，MUST NOT 直接使用主题 `AppColor.onPrimary`
