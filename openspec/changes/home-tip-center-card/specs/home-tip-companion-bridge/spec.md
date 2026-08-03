## REMOVED Requirements

### Requirement: Done tip card SHALL navigate to companion on whole-card tap

**Reason**: 进陪伴入口改为卡片下方「对话」按钮，取消整卡点击导航。  
**Migration**: 见本文件 ADDED「Done tip dialog button SHALL navigate to companion」。

## ADDED Requirements

### Requirement: Done tip dialog button SHALL navigate to companion

When the home tip panel is in `done` state with displayable text, tapping the「对话」button below the tip card MUST navigate the home PageView to the smart companion page. The tip card body MUST NOT navigate to companion on tap. 首页小贴士处于 `done` 且有可展示文本时，点击下方「对话」**必须** 将 PageView 切至智能陪伴页；**不得** 因点击卡片正文进入陪伴。

#### Scenario: 对话进入陪伴

- **WHEN** tip `displayState == done` 且用户点击「对话」
- **THEN** PageView MUST animate/jump to the companion page index
- **AND** MUST NOT auto-send a user chat question solely because of the tap（注入 tip 由 session 规则负责）

#### Scenario: 点卡片正文不进陪伴

- **WHEN** tip `displayState == done` 且用户点击卡片正文（非「对话」）
- **THEN** PageView MUST 保持在喂养页

## MODIFIED Requirements

### Requirement: Streaming tip MUST disable navigation tap

While the tip panel is `streaming`, the client MUST disable or ignore the「对话」control so that the user cannot navigate to companion from tip actions; card body taps MUST NOT navigate either. tip 处于 `streaming` 时「对话」**必须** 禁用或忽略，**不得** 经 tip 动作进入陪伴；点卡片正文也 **不得** 导航。

#### Scenario: streaming 对话无效

- **WHEN** tip `displayState == streaming` 且用户点击「对话」（若控件仍可见）
- **THEN** PageView MUST 保持在喂养页
- **AND** MUST NOT 注入未完成 tip
