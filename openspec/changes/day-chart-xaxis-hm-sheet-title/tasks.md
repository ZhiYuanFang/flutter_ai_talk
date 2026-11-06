## 1. 稀疏柱：X 轴时刻 + 柱顶量

- [x] 1.1 `_DaySparseBarChart`：`bottomTitles` 按柱显示本地 `HH:mm`
- [x] 1.2 柱顶永久标注量值（`formatTrendMetricLabel`）；不得再把时刻钉在柱顶
- [x] 1.3 预留下轴 reserved；`maxY` 略抬高给柱顶量标留空

## 2. 喂养 Sheet 标题

- [x] 2.1 标题改为居中一行 `事件名 · 日文案`（日文案更小）；去掉独立日副标题行

## 3. 验收

- [ ] 3.1 手工：趋势某日 + 喂养 Sheet — X 轴有分、柱顶有量；Sheet「名 · 日」
- [x] 3.2 不新建 `**/test/**`
