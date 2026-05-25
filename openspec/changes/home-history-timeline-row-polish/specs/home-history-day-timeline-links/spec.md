## MODIFIED Requirements

### Requirement: 连线颜色为事件色渐变

The client SHALL render each connector with a vertical linear gradient from the upper (earlier-in-day) record's event color to the lower (later-in-day) record's event color. 每条连线 **必须** 自**上一条**（时间较早）事件品牌色渐变至**下一条**（时间较晚）事件品牌色；颜色来源与行内圆点一致（`resolveEventColor` / 事件 catalog）。

#### Scenario: 相邻异色事件

- **WHEN** 上一条与下一条事件品牌色不同
- **THEN** 连线 MUST 呈现自上一事件色至下一事件色的竖向渐变，而非单色

#### Scenario: 连线透明度

- **WHEN** 绘制同日块内连接线
- **THEN** 线段视觉不透明度 MUST 为 **0.7**（在事件色渐变基础上整体应用）

### Requirement: 连线与圆点对齐

The client SHALL align connector endpoints to the vertical centers of timeline dots using shared layout metrics with `HomeHistoryTimelineTile`. 连线端点 **必须** 与圆点中心竖向对齐，且 **不得** 穿过圆点实心区域（可在圆点边缘起止）。

#### Scenario: 连线线宽

- **WHEN** 绘制连接线
- **THEN** 线宽 MUST 为 **1** logical pixel

#### Scenario: 多条记录视觉检查

- **WHEN** 用户查看同一日 3 条及以上记录
- **THEN** 连线 MUST 在相邻圆点之间连续、无明显水平或竖向错位
