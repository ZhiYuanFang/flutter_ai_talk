## ADDED Requirements

### Requirement: Dock drag reposition MUST NOT trigger outer PageView page switch

While the user is dragging the home input mode dock to reposition it (pointer movement exceeds tap slop until release), the client MUST NOT allow the parent `UcgHomeShell` PageView horizontal swipe to change pages. 当用户拖动 dock 进行 reposition（超过点击阈值至松开为止），系统 MUST NOT 触发外层喂养/广场 PageView 的横滑切页。

#### Scenario: 横向拖动 dock 不切换广场页

- **WHEN** 用户在喂养页按住 dock 并横向拖动以 reposition
- **THEN** PageView MUST remain on page 0（喂养 HomeScreen），且 MUST NOT 因该拖动切换到 page 1（广场）

#### Scenario: 拖动结束后恢复横滑

- **WHEN** 用户结束 dock 拖动（pointer up 或 cancel）且曾判定为拖动
- **THEN** PageView MUST 恢复支持横滑切换（`PageScrollPhysics` 或等价行为）

#### Scenario: 点击轮转不受影响

- **WHEN** 用户在 dock 上按下并松开，移动距离未超过 tap slop（判定为点击）
- **THEN** dock MUST 照常轮转输入模式，且 PageView 横滑能力 MUST NOT 被永久禁用
