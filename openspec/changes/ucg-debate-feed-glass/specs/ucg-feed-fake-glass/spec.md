## ADDED Requirements

### Requirement: Feed fake-glass panel SHALL replace BackdropFilter with gradient fill

The Flutter app MUST provide a shared feed fake-glass container (e.g. `UcgFeedFakeGlassPanel` / `UcgFeedFakeGlassCard`) for square debate feed cards. The container MUST use semi-transparent white blend over `AppVisualTokens.recordsCardColor`, a light primary-tinted linear gradient, a white border (alpha ≥ 0.78), and MAY use a soft outer shadow. The container MUST NOT use `BackdropFilter` or any background blur on feed list items.

Feed 假玻璃容器 MUST 使用半透明白底 + primary 轻渐变 + 白边；列表项 MUST NOT 使用 `BackdropFilter`。

#### Scenario: 推荐 Feed 卡片无 blur

- **WHEN** 用户在广场推荐 Tab 浏览辩论帖列表
- **THEN** 每张卡片外层 MUST 由假玻璃 panel 包裹
- **AND** MUST NOT 对卡片调用 `BackdropFilter`

#### Scenario: 与 compose 真玻璃职责分离

- **WHEN** 用户打开发帖 compose 页
- **THEN** compose 页 MAY 继续使用 `UcgComposeLightGlassPanel`（含 blur）
- **AND** Feed 假玻璃 panel MUST NOT 被 compose 页复用为唯一容器（避免列表误用 blur）

### Requirement: Fake-glass tokens SHALL be shared across feed surfaces

Feed fake-glass visual tokens (corner radius ~16 logical px, border color, gradient stops, optional shadow) MUST be defined once and reused by `UcgDebateFeedCard`, argument pills, and share offscreen layout wrappers so recommend and following tabs render identically.

假玻璃圆角、边框与渐变 MUST 集中定义并在 Feed 卡、论点 pill、分享布局间复用。

#### Scenario: 关注与推荐 Tab 视觉一致

- **WHEN** 用户切换广场「关注」与「推荐」子 Tab
- **THEN** 辩论卡假玻璃样式 MUST 一致（同一 panel 组件与 token）
