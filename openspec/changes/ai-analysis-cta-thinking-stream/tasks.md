## 1. Flutter 工作台 CTA 与用量

- [x] 1.1 成长工作台：主 CTA +「今日已用 x/y 次」移到正文下方；AppBar 去掉预测按钮
- [x] 1.2 喂养：解析 daily 的 `usedToday`/`dailyLimit` 写入 state；CTA 下展示同款用量文案（替换固定「每日最多」唯一提示）

## 2. Flutter 值得留意详情

- [x] 2.1 详情页强调色改为 care-alert / 喂养分析功能色（`resolveFeatureColor`）
- [x] 2.2 隐藏「忽略」「追问」底栏按钮（保留正文）

## 3. 成长轨迹 LLM 思考流（Python 为主）

- [x] 3.1 growth 图 LLM 节点改 `stream` + thinking；reasoning 经 custom/SSE `thinking` 透出（token 级不用 `\r`）
- [x] 3.2 确认 Go/Flutter 透传无过滤；手工验收编排 caption + LLM 思考衔接

## 4. Care-alert 思考 SSE（Python → Go → Flutter）

- [x] 4.1 Python：care-alert 分析流式（节点 thinking + 终态 items）；LLM 尽量 stream thinking
- [x] 4.2 Go：设备侧 SSE 代理（日限/单飞/缓存与现 daily 一致）；flush thinking
- [x] 4.3 Flutter：手动「AI智能分析」走 SSE + 思考区；结束后刷新列表与用量

## 5. 验收与约束

- [x] 5.1 手工：两工作台布局/用量；详情色与无忽略追问；成长与喂养思考流
- [x] 5.2 确认未新建 `**/test/**`；本 change 不改 `app/android/**`（无需 release/R8 专项）
