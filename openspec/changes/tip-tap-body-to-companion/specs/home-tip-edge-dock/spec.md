## MODIFIED Requirements

### Requirement: Docked tip MUST be expandable and MUST NOT equal dismiss

A tip ball on the shared edge-dock shell MUST remain associated with tip content. Peek engage and floating tap MUST restore expanded tip chrome per edge-dock baseline. Minimizing to peek/floating MUST NOT clear tip content. The client MUST NOT require a「关闭」button to undock or to keep content. tip 球 **必须** 保留 tip 内容；按贴边壳基线恢复展开卡。最小化到 peek/浮空 **不得** 清空内容；**不得** 依赖「关闭」按钮才能 undock 或保留内容。

#### Scenario: 贴边最小化非销毁

- **WHEN** tip 从 expanded 过半松手进入 edge peek
- **THEN** tip 文本 MUST 仍保留
- **AND** tip MUST NOT 因贴边而进入 idle dismiss

#### Scenario: 无关闭按钮仍可展开

- **WHEN** tip 球为 engaged 或 floating
- **AND** 用户按壳基线点按展开
- **THEN** tip MUST 变为 expanded
- **AND** MUST NOT 要求先点「关闭」
