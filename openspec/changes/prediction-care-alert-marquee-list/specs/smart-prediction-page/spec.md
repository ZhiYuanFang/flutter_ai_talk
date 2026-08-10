## REMOVED Requirements

### Requirement: Smart prediction page SHALL show at most one care-alert banner between tip and list

**Reason**: 产品改为按事件全量跑马灯展示，不再全局 Top1 单 Banner。  
**Migration**: 使用本 change「严格单行裁切跑马灯区块」Requirement。

### Requirement: Tapping care-alert banner SHALL open structured reason page

**Reason**: 点击目标改为当前跑马灯条目对应的事件聚合详情。  
**Migration**: 使用本 change「点击当前跑马灯条进入事件详情」Requirement。

## ADDED Requirements

### Requirement: Smart prediction page SHALL show a strict one-line care-alert marquee between tip and list

The smart prediction page SHALL render a「值得留意」block between the tip card region and the prediction event card area (list or grid). When aggregated care-alert event items are non-empty, the block MUST show a vertical marquee viewport that **strictly clips to exactly one content row** (MUST NOT peek the next row). The marquee MUST remain full-width and MUST NOT be laid out as a grid cell when the event cards use grid layout. When the list is empty, the page MUST hide the entire block. The block MUST remain usable when the tip card is absent.

智能预测页 tip 与事件卡片区（纵向或网格）之间 **必须** 提供「值得留意」跑马灯；有聚合项时 viewport **必须** 严格裁切只见一行（**不得** 露出下一条）；跑马灯 **必须** 全宽，**不得** 在网格布局下缩进为网格单元；无项时 **必须** 整块隐藏；tip 缺失时区块 **仍可** 单独出现。

#### Scenario: 多条严格单行

- **WHEN** 存在 2 个及以上事件聚合留意项
- **THEN** 跑马灯可见区域 MUST 只完整显示当前一条内容行
- **AND** MUST NOT 同时露出下一条的可见片段

#### Scenario: 网格布局下仍全宽

- **WHEN** 事件卡片为网格（左右）排列且存在留意项
- **THEN** 值得留意跑马灯 MUST 仍为全宽置于卡片区上方
- **AND** MUST NOT 与事件卡同处同一网格单元格

#### Scenario: 无项隐藏

- **WHEN** 聚合留意列表为空
- **THEN** 页面 MUST NOT 渲染值得留意区块占位

### Requirement: Care-alert marquee SHALL auto-scroll when multiple items and allow manual scroll

When there are two or more aggregated items, the marquee SHALL automatically advance vertically through items in a loop. When there is exactly one item, the marquee MUST remain static (no idle spinning). The user MUST be able to manually scroll to a specific item. After a manual scroll interaction, auto-advance MAY pause briefly then resume.

≥2 条时 **必须** 自动上下循环轮播；恰 1 条时 **必须** 静止；用户 **必须** 能手动滚到目标条。

#### Scenario: 单条不空转

- **WHEN** 仅有 1 个事件聚合留意项
- **THEN** 区块 MUST 静止展示该条
- **AND** MUST NOT 无意义自动翻页

#### Scenario: 手动可达目标条

- **WHEN** 存在多条聚合项且用户向上/下滑动跑马灯
- **THEN** 客户端 MUST 能将目标条滚入当前严格单行视口

### Requirement: Tapping the current marquee item SHALL open that event’s full-reason detail

Tapping the currently visible marquee item SHALL navigate to the care-alert detail route with that event’s aggregated payload so the detail page can show all firing reasons for the event (not only a one-line summary).

点击当前可见跑马灯条 **必须** 进入该事件留意详情，并 **必须** 能展示该事件全部命中原因。

#### Scenario: 点进对应事件详情

- **WHEN** 跑马灯当前条为事件 A，用户点击该条
- **THEN** 客户端 MUST 导航至护理留意详情
- **AND** 详情 MUST 对应该事件 A 的聚合原因集合
