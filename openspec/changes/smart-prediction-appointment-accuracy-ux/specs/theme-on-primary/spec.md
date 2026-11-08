## ADDED Requirements

### Requirement: Theme SHALL keep onPrimary paired with overridden primary

When the app builds `ColorScheme` and overrides `primary` (including dark-shell seed primary), it MUST also set `onPrimary` to a foreground that contrasts with that primary (e.g. via brightness estimation). Solid primary actions (history edit save, event record confirm, appointment confirm) MUST use `AppColor.onPrimary` / `colorScheme.onPrimary` and MUST NOT hard-code `Colors.white` or `Colors.black` as the button label color. 覆盖 primary 时 MUST 同步 onPrimary；实心主钮字色 MUST 走 onPrimary，MUST NOT 写死黑/白。

#### Scenario: Dark shell save label readable

- **WHEN** 深色壳主题下打开历史编辑 sheet 点「保存」
- **THEN** 按钮文字色 MUST 为与按钮底 primary 成对的 onPrimary，且在深色壳下可读

#### Scenario: Record sheet uses onPrimary

- **WHEN** 统一记录 sheet 展示主确认钮
- **THEN** 前景 MUST 使用 `AppColor.onPrimary`（或等价），MUST NOT 写死 `Colors.white`
