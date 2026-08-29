## ADDED Requirements

### Requirement: UCG square SHALL toggle list and waterfall layouts with PK full-width

The UCG square tab MUST provide a top-right layout toggle (before or adjacent to the theme palette action) that switches between a vertical list layout and a waterfall (multi-column) layout. The preference MUST persist locally across launches. In waterfall mode, PK/debate posts (`isDebate`) MUST always occupy the full content width as an interrupting full-width band, not a single masonry cell. In list mode, all posts including debate remain full-width as today.

UCG 广场 **必须** 在右上角提供列表 ↔ 瀑布流切换并本地持久化；瀑布流中 PK/辩论帖 **必须** 始终全宽打断，不得缩成单列瀑布格。

#### Scenario: 切换布局

- **WHEN** 用户点击广场右上角布局切换图标
- **THEN** Feed MUST 在列表与瀑布流之间切换
- **AND** 再次冷启动后 MUST 恢复用户上次选择（本地 prefs）

#### Scenario: 瀑布流 PK 全宽

- **WHEN** 布局为瀑布流且 Feed 中出现辩论/PK 帖
- **THEN** 该帖 MUST 以全宽行展示
- **AND** 其上下普通帖可继续双列瀑布排列

#### Scenario: 列表模式全宽

- **WHEN** 布局为列表
- **THEN** 普通帖与辩论帖 MUST 均为全宽纵向列表项
