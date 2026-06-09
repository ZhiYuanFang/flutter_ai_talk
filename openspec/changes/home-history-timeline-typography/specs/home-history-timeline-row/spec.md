## MODIFIED Requirements

### Requirement: 主页历史时间轴行 MUST 分层展示事件名、备注与尾注数字

The home history timeline row SHALL render the event name at 1.5× base size, remark at base size, and trailing numeric digits at 2× bold with event accent color while unit suffixes remain base size. Count events MUST show quantity plus `eventUnit` without a leading arrow. 主页历史行 MUST 将事件名放大 1.5×、备注原字号、尾注数字 2× 加粗并使用事件强调色；计数尾注 MUST 展示「数量+单位」且不得使用 `→` 前缀。

#### Scenario: 计数事件展示 120ml

- **WHEN** 历史行 `eventNumber=120` 且 payload `eventUnit=ml`
- **THEN** 尾注 MUST 强调显示 `120` 与正常字号 `ml`，且 MUST NOT 显示 `→120`

#### Scenario: 计时 duration 数字强调

- **WHEN** 已结束计时行尾注为「用时5分钟」
- **THEN** 数字 `5` MUST 使用与计数尾注相同的 2× 加粗强调色样式，「用时」「分钟」为正常字号

#### Scenario: 行高略增仍单行

- **WHEN** 渲染任意标准历史行
- **THEN** 行高 MUST 约为 40 逻辑像素且中间与尾注主文案 MUST NOT 超过 1 行
