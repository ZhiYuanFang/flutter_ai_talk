## REMOVED Requirements

### Requirement: Done tip dialog button SHALL navigate to companion

**Reason**: 进陪伴入口改回文案区点击。  
**Migration**: 见本文件 ADDED「Done tip body tap SHALL navigate to companion」。

## ADDED Requirements

### Requirement: Done tip body tap SHALL navigate to companion

When the home tip panel is expanded and `displayState` is `done` with injectable text, a tap on the tip text/body area (not the top badge) MUST navigate the home PageView to the smart companion page using the same injection rules as the former「对话」control. 首页 tip 展开且为 `done`、具备可注入文案时，点击**文案/正文区域**（非顶标）**必须** 将 PageView 切至智能陪伴页，注入规则与原「对话」一致。

#### Scenario: done 点文案进陪伴

- **WHEN** tip `displayState == done` 且可注入
- **AND** 用户点击展开卡正文（未超过拖动 slop）
- **THEN** PageView MUST animate/jump to the companion page index

#### Scenario: 点顶标不进陪伴

- **WHEN** tip 为 expanded
- **AND** 用户点击顶部胖宝圆标
- **THEN** tip MUST NOT 因此导航至陪伴（顶标仍按折叠规则处理）

### Requirement: Streaming tip body tap MUST NOT navigate to companion

While the tip panel is `streaming` (or otherwise not `done`), a tap on the tip body MUST NOT navigate to companion. tip 非 `done`（含 streaming）时，点正文 **不得** 进入陪伴。

#### Scenario: streaming 点文案无效

- **WHEN** tip `displayState == streaming`
- **AND** 用户点击正文
- **THEN** PageView MUST NOT 切至陪伴页
