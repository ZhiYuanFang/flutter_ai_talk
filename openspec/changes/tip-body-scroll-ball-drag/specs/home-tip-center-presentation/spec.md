## REMOVED Requirements

### Requirement: Tip body MUST NOT use scroll view as primary layout

**Reason**: 产品要求长文案在展开卡内滚动阅读。  
**Migration**: 见 ADDED「Expanded tip body MUST scroll」。

## ADDED Requirements

### Requirement: Expanded tip body MUST scroll when content overflows

When the tip is expanded and content exceeds the card max height, the client MUST allow vertical scrolling within the tip body to reveal remaining text. 展开 tip 正文超出卡片最大高度时，客户端 **必须** 允许在正文区域内竖向滚动以展示剩余文案。

#### Scenario: 超高文案可滚

- **WHEN** tip 为 expanded 且正文高度超过卡片约束
- **AND** 用户在正文区竖向拖动
- **THEN** 正文 MUST 滚动展示被裁切内容
- **AND** 卡片自身 MUST NOT 随该手势平移
