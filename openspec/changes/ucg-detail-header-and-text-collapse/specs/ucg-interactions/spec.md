## ADDED Requirements

### Requirement: Detail post body SHALL collapse beyond five lines with one-way expand

`UcgPostDetailScreen` SHALL display `post.text` collapsed to at most **five lines** when longer. When collapsed text exceeds five lines, UI SHALL show tappable「展开」below the text. Tapping SHALL reveal the full body and SHALL NOT offer「折叠」. When text fits within five lines, UI SHALL NOT show「展开」.

#### Scenario: 长正文默认折叠
- **WHEN** 帖子正文在详情页布局宽度下超过 5 行
- **THEN** UI SHALL 展示前 5 行与「展开」链接

#### Scenario: 短正文无展开
- **WHEN** 正文不超过 5 行
- **THEN** UI SHALL 全量展示且 SHALL NOT 显示「展开」

#### Scenario: 展开后无折叠
- **WHEN** 用户点击「展开」
- **THEN** UI SHALL 展示全文且 SHALL NOT 显示「折叠」
