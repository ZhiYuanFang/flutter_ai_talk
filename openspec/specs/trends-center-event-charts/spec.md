## ADDED Requirements

### Requirement: 事件目录加载与用户单选

The client SHALL 在趋势中心进入且具备拉取条件时（已登录且已绑定 `deviceNo` 等，与现有仓库前置一致），调用服务端事件目录接口加载可选事件列表，并以交互控件呈现**单选**状态。用户变更所选事件时，客户端 MUST 仅加载并展示该事件对应的数据，不得在无选择或无效选择时静默请求全部事件的 `piece` 全量列表作为默认主视图。

#### Scenario: 目录加载成功后可选中第一项

- **WHEN** 事件目录接口返回非空列表  
- **THEN** 客户端 MUST 提供可见的单选控件，且 MUST 能选中至少一个事件以触发后续序列加载

#### Scenario: 目录为空

- **WHEN** 事件目录接口返回空列表或失败  
- **THEN** 客户端 MUST 展示空态或错误提示，且不得展示误导性的伪造趋势图

### Requirement: 趋势折线与量柱展示

The client SHALL 对当前选中事件在所选时间范围（今日/周/月/季等既有粒度）内展示**趋势折线**与**量柱**两类视觉编码，二者 MUST 基于同一批 `piece` 记录派生，横轴 MUST 能区分时间先后（实现可用索引或格式化时间标签）。

#### Scenario: 切换时间范围

- **WHEN** 用户更改时间范围分段控件  
- **THEN** 客户端 MUST 以新范围重新请求当前选中事件的序列并刷新折线与量柱

### Requirement: 计时类事件以时段为量

The client SHALL 对 `event_number == 0` 的样本将**量值**定义为该条记录**结束时刻与开始时刻之差**（持续时长）；时间字段解析语义 MUST 与历史详情/首页所用「开始、结束、未设置」规则一致。若结束时间未设置或无效，该条目的量值 MUST 为 `0` 或按设计文档固定策略不参与柱高（须在实现中与规格一致并单一选择）。

#### Scenario: 计时条有效起止

- **WHEN** 单条 `piece` 数据中 `eventNumber == 0` 且 `startTime` 与 `endTime` 均可解析为有效时刻且结束不早于开始  
- **THEN** 用于量柱的标量 MUST 等于 `endTime - startTime` 的时长换算为 **小时**（`double`，与纵轴单位一致）

#### Scenario: 计时条无结束

- **WHEN** `eventNumber == 0` 且 `endTime` 按未设置规则判定为无效  
- **THEN** 该条用于量柱的标量 MUST 为 `0`（或规格选择的「不绘制柱」策略），且不得抛未捕获异常

### Requirement: 非计时类事件的量

The client SHALL 对 `event_number != 0` 的样本将量柱标量定义为网关提供的计数语义（与现有 `piece` 解析中的数值字段一致，通常为 `eventNumber` 的数值表示），不得错误套用时段差公式。

#### Scenario: 多次计数事件

- **WHEN** `eventNumber > 0`  
- **THEN** 量柱标量 MUST 反映该计数值（与折线若共用同一序列则取值一致）
