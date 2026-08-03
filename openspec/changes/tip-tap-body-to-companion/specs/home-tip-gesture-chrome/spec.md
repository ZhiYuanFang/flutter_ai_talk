## MODIFIED Requirements

### Requirement: Expanded tip drag unit MUST include badge and card body

While the tip is expanded, dragging MUST treat the top Pangbao round badge and the tip card body as one draggable unit. There MUST be no「关闭」/「对话」controls in the expanded chrome. 展开态拖动 **必须** 将顶部胖宝圆标与正文卡视为同一拖动单元；展开 chrome **不得** 含「关闭」「对话」。

#### Scenario: 正文可拖无底栏

- **WHEN** tip 为 expanded
- **AND** 用户在正文区域拖动超过 slop
- **THEN** 卡片 MUST 随指针平移
- **AND** MUST NOT 因该拖动进入陪伴

## ADDED Requirements

### Requirement: Tip body tap versus pan MUST use drag slop

On the tip body, a pointer up that never exceeded drag slop MUST be treated as a tap (eligible for companion navigation when done); a gesture that exceeded slop MUST be treated as pan only. 正文手势：未过拖动 slop 的抬起 **必须** 视为点按（done 时可进陪伴）；超过 slop **必须** 仅作拖动。

#### Scenario: 轻点进陪伴拖动不进

- **WHEN** tip 为 done expanded
- **AND** 用户在正文按下并移动超过 slop 后松开
- **THEN** tip MUST 按拖动/吸附规则处理
- **AND** MUST NOT 导航至陪伴
