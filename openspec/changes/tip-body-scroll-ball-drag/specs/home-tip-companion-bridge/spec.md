## ADDED Requirements

### Requirement: Done tip body tap MUST navigate without pan or selection capture

When tip is expanded and injectable (`done` with injectable text), a tap on the tip body MUST navigate to companion; the expanded chrome MUST NOT register pan-drag on the body that cancels this tap, and tip body text MUST NOT use selection gestures that prevent the tap. tip 展开且可注入时，点正文 **必须** 进陪伴；展开 chrome **不得** 在正文注册会取消该 tap 的 pan；tip 正文 **不得** 用选区手势阻止 tap。

#### Scenario: done 点文案进陪伴

- **WHEN** tip `canInjectToCompanion`
- **AND** 用户轻点正文（非顶标、非滚动位移）
- **THEN** PageView MUST 切至陪伴页

#### Scenario: streaming 仍不进

- **WHEN** tip 非 done 或不可注入
- **AND** 用户点正文
- **THEN** PageView MUST NOT 切至陪伴页
