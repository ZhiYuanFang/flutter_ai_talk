## ADDED Requirements

### Requirement: 发生点位于四段背景带垂直中心

Count-day timeline occurrence markers SHALL sit at the vertical center of the four day-part background bands.

计次时间轴上每个发生点 MUST 画在四时段背景带的垂直中心，MUST NOT 落在背景带底边轴线位置。

#### Scenario: 单点居中

- **WHEN** 选中日有一条计次发生
- **THEN** 该发生点 MUST 处于背景色带垂直中部

### Requirement: 时刻文案留在背景带内且细线长度不变

Occurrence time labels SHALL remain inside the background band area; the thin leader line below each marker SHALL keep approximately the current short length and MUST NOT be lengthened to push labels outside the band.

发生点对应的 `HH:mm` 文案 MUST 位于背景色区域内，MUST NOT 跨出背景色带外。点下细线长度 MUST 保持与现网短细线相当，MUST NOT 为了把文案甩到带外而加长。

#### Scenario: 时刻在带内

- **WHEN** 时间轴绘制带有时刻标注的发生点
- **THEN** 时刻文字 MUST 仍落在四段背景填充范围内，且细线未明显加长

### Requirement: 轴时刻刻度与背景带分离

Bottom hour tick labels (0/6/12/18/24) SHALL sit below the background bands with clear separation from the band fill.

X 轴 0/6/12/18/24 刻度文案 MUST 位于背景带下方并与带有间距，避免贴死在背景色边缘。

#### Scenario: 刻度下移

- **WHEN** 计次时间轴渲染完成
- **THEN** 小时刻度 MUST 在背景带下方可读，且不与带内时刻标注抢同一垂直位置
