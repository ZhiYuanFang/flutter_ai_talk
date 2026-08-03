## MODIFIED Requirements

### Requirement: Clinic empty conversation gallery

When the smart companion chat has no messages, the client MUST show an empty-state gallery (animation or icon, title, subtitle) using companion wording (not clinic/medical primary branding). If the user is not logged in, the gallery MUST include a login action. If logged in without device binding, MUST include bind-baby action. Subtitle MUST NOT claim Q&A is retained only for 12 hours.

智能陪伴空态 **必须** 使用陪伴语境文案；未登录/未绑宝行为延续；**不得** 声称仅保留 12 小时。

#### Scenario: Guest opens companion

- **WHEN** the user opens 智能陪伴 without a session
- **THEN** the client MUST show empty-state copy and a「去登录」button
- **AND** MUST disable question input until logged in and device-bound

#### Scenario: Empty state without 12-hour retention claim

- **WHEN** 已登录已绑宝且会话为空
- **THEN** 空态副文案 MUST NOT 包含「12个小时」或等价时限清理表述
