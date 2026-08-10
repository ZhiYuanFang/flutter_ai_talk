## ADDED Requirements

### Requirement: Home prediction tip bar MUST NOT offer skip

The feeding-home fixed prediction tip bar MUST NOT show a「跳过」control and MUST NOT write hero-skip state from the home tip bar. Tapping the tip bar MUST still open the smart prediction page. Tip selection MAY continue to exclude events already skipped via the widget hero-skip store and forecast-disabled events.

喂养页顶部预测贴士 **不得** 展示「跳过」、**不得** 从该贴士写入 hero-skip；点击贴士 **必须** 仍进入智能预测页。选条 **可以** 继续排除小组件已 skip 与推演关闭的事件。

#### Scenario: 无跳过按钮

- **WHEN** 顶栏展示一条可预测贴士
- **THEN** UI MUST NOT 显示「跳过」按钮
- **AND** MUST NOT 因顶栏操作调用 `WidgetHeroSkipStore` / `applyWidgetHeroSkipAndRefresh`（或等价主页写 skip）

#### Scenario: 点击贴士进预测

- **WHEN** 用户点击顶栏预测贴士（任意非冲突控件区域）
- **THEN** 客户端 MUST 导航至智能预测页

## REMOVED Requirements

### Requirement: Tip skip SHALL reuse widget hero skip store

**Reason**: 产品去掉喂养顶栏「跳过」；skip 仅保留小组件等其它入口（若有）。  
**Migration**: 删除顶栏跳过 UI 与 `_skipTip`；选条仍可读既有 skip store。
