## ADDED Requirements

### Requirement: Feed fake glass panel SHALL provide debate card surface without blur

The App MUST provide a shared fake-glass panel for square debate full-width cards (`UcgFeedFakeGlassPanel` or equivalent): semi-transparent white fill, thin light border, optional primary-tint gradient, and light shadow. The panel MUST NOT use `BackdropFilter` or real-time backdrop blur. Moment masonry cards MUST continue using light-surface `UcgSurfaceCard` per v2.0.3.

Feed 辩论全宽卡 MUST 使用无 blur 假玻璃 panel；moment 双列卡 MUST 保持轻表面。

#### Scenario: 列表滚动无 BackdropFilter

- **WHEN** 用户在广场滚动含多条辩论全宽卡
- **THEN** 辩论卡容器 SHALL NOT 使用 `BackdropFilter`
- **AND** Web 与离屏分享路径 SHALL 使用同一假玻璃绘制逻辑

#### Scenario: moment 卡仍为轻表面

- **WHEN** 用户在广场浏览非辩论 masonry 帖
- **THEN** 卡片 SHALL 使用 `UcgSurfaceCard` 或等价轻表面
- **AND** SHALL NOT 套用辩论假玻璃 panel
