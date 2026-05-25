## ADDED Requirements

### Requirement: 同一日期内相邻记录圆点连线

The client SHALL draw vertical connector segments between the timeline dots of consecutive history records within the same calendar-day card. 同一 `HomeHistoryDayGroup` 卡片内，**相邻**两条记录左侧圆点之间 **必须** 绘制竖向连线。

#### Scenario: 同一日多条记录

- **WHEN** 某日卡片内存在至少 2 条历史记录
- **THEN** 客户端 MUST 在每一对相邻记录圆点之间绘制一条竖向连线

#### Scenario: 同一日仅一条记录

- **WHEN** 某日卡片内仅有 1 条历史记录
- **THEN** 客户端 MUST NOT 绘制任何连线

#### Scenario: 跨日期不连线

- **WHEN** 两条记录分属不同日历日卡片
- **THEN** 客户端 MUST NOT 在它们之间绘制连线

### Requirement: 连线颜色为事件色渐变

The client SHALL render each connector with a vertical linear gradient from the upper (earlier-in-day) record's event color to the lower (later-in-day) record's event color. 每条连线 **必须** 自**上一条**（时间较早）事件品牌色渐变至**下一条**（时间较晚）事件品牌色；颜色来源与行内圆点一致（`resolveEventColor` / 事件 catalog）。

#### Scenario: 相邻异色事件

- **WHEN** 上一条与下一条事件品牌色不同
- **THEN** 连线 MUST 呈现自上一事件色至下一事件色的竖向渐变，而非单色

#### Scenario: 未知事件色

- **WHEN** 某条记录无法解析事件定义色
- **THEN** 连线 MUST 使用该记录圆点相同的 fallback 色参与渐变

### Requirement: 连线不干扰行交互与内容

The client MUST place connector painting behind row content and MUST NOT reduce the tappable area of history rows. 连线 **必须** 位于行内容后方绘制，**不得** 遮挡 logo、文字或削弱整行点击（含尾注「用时」区域）。

#### Scenario: 点击含连线的行

- **WHEN** 用户点击某日卡片内任意一行（含圆点列或右侧尾注）
- **THEN** 行为 MUST 与变更前一致（打开编辑 Sheet 等）

### Requirement: 连线与圆点对齐

The client SHALL align connector endpoints to the vertical centers of timeline dots using shared layout metrics with `HomeHistoryTimelineTile`. 连线端点 **必须** 与圆点中心竖向对齐，且 **不得** 穿过圆点实心区域（可在圆点边缘起止）。

#### Scenario: 多条记录视觉检查

- **WHEN** 用户查看同一日 3 条及以上记录
- **THEN** 连线 MUST 在相邻圆点之间连续、无明显水平或竖向错位
