## ADDED Requirements

### Requirement: Tip panel done state MUST NOT include feedback thumbs

When the home tip panel is in `done` state, the client MUST NOT render thumbs-up or thumbs-down controls. Whole-card navigation to companion (when enabled) and the close control MUST remain available per existing tip-bridge rules. tip 处于 `done` 时 **不得** 渲染赞/踩；整卡进陪伴与关闭控件按既有 tip-bridge 规则保留。

#### Scenario: done 态无赞踩仍可关闭

- **WHEN** tip `displayState == done`
- **THEN** 面板 MUST NOT 展示赞或踩
- **AND** 关闭按钮 MUST 仍可用（若产品仍提供关闭）
