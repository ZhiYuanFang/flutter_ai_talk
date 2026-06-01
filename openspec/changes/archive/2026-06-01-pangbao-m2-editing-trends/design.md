## 背景

在 `pangbao-app` M1 已实现导航、Mock 历史、趋势与设置的基础上，本变更补齐**可编辑宝宝信息**、**历史展示与详情编辑**、**Web Enter 提交**与**趋势今日 + 坐标轴**等产品规则，仍优先使用 Mock 仓库与本地持久化，便于后续替换为 REST。

## 目标与非目标

**目标：**

- 扩展 `BabyProfile`（或等价模型）与 `SettingsRepository`：读写在设置页完成，保存后更新 `babySexProvider` 等主题来源。
- 历史行渲染与路由：`/history/:id` 或 query 携带 id；详情页表单编辑后调用 `FeedRepository.updateRecord`（新增接口）或复用 `sendCommand` 的「修正」语义（设计选定一种并在任务中落实）。
- Web：`TextField`/`TextFormField` 监听 `TextInputAction.done` 与 `onSubmitted`，并与 `RawKeyboardListener`/`Shortcuts` 二选一，确保 Enter 行为符合「单行提交、多行 Shift+Enter」约定。
- 趋势：`TrendRange` 增加 `today` 或在 UI 增加「今日」分段；`fl_chart` 的 `FlTitlesData`/`SideTitles` 显示日期（横轴）与数值（纵轴），避免全关坐标。

**非目标：**

- 真实后端字段级联、冲突解决、离线队列。
- 复杂富文本历史、附件、语音条内嵌播放。

## 技术决策

| 决策 | 理由 |
|------|------|
| 历史详情路由 | 使用 `go_router` 新增 `GoRoute` `path: '/history/:recordId'`，参数由列表 `extra` 或仅从仓库按 id 拉取。 |
| 历史行格式 | UI 层拼接 `eventName` + `:` + `action`；若字段缺失显示 `未知事件:未命名动作` 类占位，满足「不得空白行」验收。 |
| 保存 | Mock：`MockFeedRepository` 内 `Map`/`List` 按 id 更新；`shared_preferences` 可选持久化列表快照。 |
| Web Enter | 默认 **单行**：`maxLines: 1` + `onSubmitted`；若保留多行则采用 **Shift+Enter 换行、Enter 提交** 并在 README 说明。 |
| 趋势今日 | 以设备本地日界 `DateTime.now()` 的 calendar day 过滤 `TrendPoint.t`；Mock 生成当日密一点。 |
| 坐标轴 | `bottomTitles` 用 `date.month/day` 短格式；旋转或间隔避免重叠；纵轴 `leftTitles` 显示数值刻度。 |

## 风险与取舍

| 风险 | 缓解 |
|------|------|
| Web 多行与 Enter 语义冲突 | 产品默认单行；若多行必须写清快捷键表。 |
| 历史 id 在 SSE 新条目中变化 | 详情页保存后 `pop` 并刷新列表；id 用服务端稳定 id 字段。 |
| 图表日期多时横轴拥挤 | 限制今日点数或自动稀疏刻度标签。 |

## 迁移计划

1. 合并本变更任务后跑 `flutter analyze` 与 Web/移动端烟测。
2. 对接真实 API 时替换仓库实现，保留 UI 契约。

## 待决问题

- 历史「动作」字段是否与语音指令原文一致，还是服务端解析后的规范化动词（由后端最终定）。
