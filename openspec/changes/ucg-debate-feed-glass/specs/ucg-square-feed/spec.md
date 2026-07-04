## MODIFIED Requirements

### Requirement: Square feed masonry cards SHALL use light-surface containers

Masonry feed cards on 广场 SHALL wrap **debate** content in a **fake-glass** container (`UcgFeedFakeGlassPanel` / `UcgFeedFakeGlassCard` or equivalent): semi-transparent white blend over `AppVisualTokens`, `surfaceRadius` (~16 logical px), padding ~12, white border, light primary gradient fill, and optional soft shadow. Cards MUST NOT use `BackdropFilter`. Inline argument rows MAY use light primary-tint pills without blur. Cards SHALL contain topic + `UcgDebateVsBar` + optional inline arguments instead of media cover.

广场辩论卡 MUST 使用假玻璃容器（渐变+白边，无 blur）包裹话题、VS 条与论点。

#### Scenario: 推荐 Feed 假玻璃卡片

- **WHEN** 用户在广场推荐或关注 Feed 浏览辩论帖
- **THEN** 每张卡片 SHALL 展示为假玻璃圆角矩形（可读白边与轻渐变）
- **AND** MUST NOT 使用磨砂 blur

#### Scenario: 卡片交互为就地投票

- **WHEN** 用户与广场辩论卡 VS 条交互
- **THEN** 行为 SHALL 触发 vote API 且 MUST NOT 导航至详情

#### Scenario: 论点区轻 tint 不 blur

- **WHEN** 卡片展示内联论点行
- **THEN** 每条论点 MAY 使用 primary 低透明度圆角 pill 背景
- **AND** MUST NOT 对论点行单独使用 `BackdropFilter`
