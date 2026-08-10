## ADDED Requirements

### Requirement: Home prediction tip skip SHALL share widget hero skip store

When the feeding-home prediction tip bar activates「跳过」for the current tip `eventId`, the client MUST use the same local skip store, baseline, reconcile, and lifetime rules as desktop widget hero skip (`WidgetHeroSkipStore` / existing hero skip requirements). After skip, both the tip bar and the widget hero MUST exclude still-skipped ids and promote the next eligible prediction when available.

喂养顶栏预测贴士「跳过」**必须** 与桌面小组件 hero skip 共用存储与生命周期；跳过后顶栏与 hero **必须** 同步排除仍 skip 的事件并提升下一条。

#### Scenario: 顶栏跳过写入同一 store

- **WHEN** 用户在喂养顶栏对事件 A 点击「跳过」
- **THEN** 客户端 MUST 以与小组件 hero 相同的 skip 映射记录 A
- **AND** 顶栏 MUST 不再展示 A 直至 skip 按既有规则解除

#### Scenario: 小组件跳过影响顶栏

- **WHEN** 用户在桌面小组件对 hero 事件 A 点击「跳过」且 App 内 history/预测状态随后刷新
- **THEN** 喂养顶栏「最近下一步」MUST NOT 选用仍处于 skip 的 A
