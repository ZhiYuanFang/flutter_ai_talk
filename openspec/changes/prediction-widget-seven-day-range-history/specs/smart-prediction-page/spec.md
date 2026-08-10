## MODIFIED Requirements

### Requirement: Entering prediction page SHALL prefetch seven-day history with chart loading

When the user navigates to the smart prediction page and the isolated seven-day range history store is not ready, the client MUST ensure that store via the range history API (same path as widget prediction: `filter` / `v2/list` for local `[today-6d start, now]`), using single-flight shared with widget range ensure. The client MUST NOT background-page `homeHistory` / `loadNextHistoryPage` to span seven days for this purpose. While the range fetch is in flight, each forecast-enabled row’s chart area MUST show a loading affordance（「正在加载中」or equivalent）instead of treating missing range data as a final empty chart.

进入预测页时 **必须** ensure 独立 7 日 range store（与小组件同源接口）；**不得** 再分页拉取 `homeHistory`；拉取期间图区 **必须** 显示加载中。

#### Scenario: 拉取中图区 loading

- **WHEN** 用户进入预测页且 7 日 range 尚未就绪
- **THEN** 推演开启事件的折线区域 MUST 显示加载中
- **AND** MUST NOT 以「近 7 日暂无记录点」作为 range 完成前的最终态（若仅因未加载）

#### Scenario: range 就绪后出图

- **WHEN** range store 已成功加载且某事件在窗口内有每日代表点
- **THEN** 该事件折线 MUST 按每日一点规则渲染

#### Scenario: 不调用喂养 loadMore

- **WHEN** 用户仅打开智能预测页触发 7 日 ensure
- **THEN** 客户端 MUST NOT 因此调用 `loadNextHistoryPage` 以加深喂养列表
