## ADDED Requirements

### Requirement: Care-alert detail SHALL use feeding-analysis feature accent

The care-alert（值得留意）detail screen SHALL use the care-alert / feeding-analysis feature accent from `resolveFeatureColor` (or equivalent catalog accent) for primary chrome and emphasis text, and MUST NOT rely solely on the app theme `ColorScheme.primary` / shell tokens for those accents. 值得留意详情 **必须** 跟随喂养分析功能色，**不得** 仅用 App 主题主色充当强调。

#### Scenario: 详情强调色跟功能色

- **WHEN** 用户从喂养列表打开值得留意详情
- **THEN** 标题区/摘要/玻璃描边等强调色 MUST 与喂养分析功能色一致（可加深以保证浅底可读）

### Requirement: Care-alert detail SHALL hide ignore and follow-up actions

The care-alert detail screen MUST NOT present「忽略」or「追问」controls while smart follow-up UX is not product-ready. Related local/API helpers MAY remain in code but MUST NOT be reachable from this screen’s primary UI. 详情 **不得** 展示忽略/追问入口。

#### Scenario: 无底栏双按钮

- **WHEN** 用户打开值得留意详情
- **THEN** 界面 MUST NOT 显示「忽略」与「追问」按钮
- **AND** MUST 仍可展示原因与说明正文
