## ADDED Requirements

### Requirement: Next-3-hours card SHALL stay visible with empty-window copy when bound

On the smart prediction page, when the user is logged in and baby-bound (not auth-guest chrome), the client MUST always show the「接下来3小时」card, including when there are no in-window forecast segments for the next three hours. When segments exist, the body MUST remain the existing joined timeline text (`HH:mm 左右{事件名}` connected by「 → 」). When segments are empty, the body MUST be exactly：`接下来 3 小时暂无事项，享受属于自己的时光吧。` The title row「AI分析」entry and tap split (AI analysis vs feeding) MUST remain available in both cases. Auth-guest chrome MUST continue to hide this card. This supersedes the prior rule that the block MUST NOT be shown when there are no in-window segments. 已绑定态下三小时卡 **必须** 常显；空窗正文 **必须** 为指定庆祝/空闲文案；「AI分析」入口 **必须** 仍可用；Auth 冷态仍隐藏。

#### Scenario: Empty window shows card with fixed copy

- **WHEN** the user is logged in and bound
- **AND** there are no forecast-enabled in-window events for the next three hours
- **THEN** the「接下来3小时」card MUST still be visible
- **AND** the body text MUST be「接下来 3 小时暂无事项，享受属于自己的时光吧。」
- **AND** the「AI分析」control MUST be visible and open the AI analysis page

#### Scenario: Non-empty window unchanged

- **WHEN** the user is logged in and bound
- **AND** there is at least one in-window timeline segment
- **THEN** the body MUST show the joined timeline segments as before
- **AND** the「AI分析」control MUST remain available

#### Scenario: Auth guest still hides the card

- **WHEN** the user is not logged in or not baby-bound (auth-guest chrome)
- **THEN** the client MUST NOT show the「接下来3小时」card (including empty copy)
