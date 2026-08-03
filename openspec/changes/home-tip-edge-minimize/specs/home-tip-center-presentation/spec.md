## ADDED Requirements

### Requirement: Tip card MUST show a centered top Pangbao round badge

When the tip is expanded and visible, the client MUST show a circular Pangbao flat-round image badge centered on the top edge of the tip card. 展开可见时，客户端 **必须** 在卡片顶缘居中展示胖宝平拍圆图徽章。

#### Scenario: 顶标可见

- **WHEN** tip expanded 且 shouldShow
- **THEN** 卡片顶部居中 MUST 出现圆形胖宝平拍图

### Requirement: Close and dialog buttons MUST use opaque default backgrounds

The「关闭」and「对话」controls below the tip card MUST render with non-transparent default background fills (not outline-only transparent fills). tip 下方「关闭」「对话」默认态 **必须** 使用不透明背景填充，**不得** 仅为透明底描边按钮。

#### Scenario: 按钮实色

- **WHEN** tip expanded 且底部操作行可见
- **THEN** 「关闭」与「对话」MUST 各自具有可见不透明底色（对话禁用时 MAY 降低不透明度但仍须有底）

### Requirement: Tip body MUST NOT use scroll view as primary layout

The expanded tip body MUST NOT wrap answer/thinking content in a scroll view as the primary layout; content is assumed length-limited so it fits the card height (overflow MAY clip). 展开态正文 **不得** 以 ScrollView 作为主布局；假定文案限长适配高度（溢出 MAY 裁剪）。

#### Scenario: 无滚动容器

- **WHEN** tip expanded 展示 thinking 或 answer
- **THEN** 正文区域 MUST NOT 为用户可滚动的主路径（无 SingleChildScrollView 或等价）
