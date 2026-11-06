## Why

间隔预测用 6 个粗时段桶做「同档 / 相邻 / 全桶」投票，会把 18:00 与 20:00 等不同钟点绑在同一桶里；日末锚点易被桶内短间隔拉向「当晚再来一次」，或在短/长双峰间中位翻簇。用户习惯因人因事件而异，不能写死夜晚钟点。需要：**按与 `lastAt` 的钟点相近程度连续加权（A）**，并对估出的 `nextAt` 用该事件自己的 **历史钟点直方图密度护栏（D）** 拒绝落在冷区的预测。

## What Changes

- **废止**以 6 桶 + 同档→相邻→全桶阶梯回退作为间隔投票主路径；改为间隔起点与 `lastAt` 的**本地钟点环形距离**连续亲和权重，再乘既有时间衰减 / 月龄半衰期，对有效样本做加权中位；`nextAt = lastAt + interval` 公式不变。
- 低亲和权重样本 MUST 可截断（低于阈值视为不参与）；有效样本仍不足时保留既有种子间隔旁路与「不可预测」门闸；最短 15 分钟间隔过滤保留。
- **新增**按事件根的历史发生钟点 **环形直方图**（建议 30 分钟一格，可邻格平滑）：候选 `nextAt` 的钟点相对峰值过低则拒绝；样本过少时 MUST NOT 强行启用护栏。
- 护栏拒绝后 MUST 尝试「更长间隔 / 跨自然日」类候选（在亲和加权样本中偏好更长一分位或跨日间隔中位），仍失败则该根不可预测；MUST NOT 写死 20:00 等全局夜晚边界。
- 发生时刻继续沿用 `predict-interval-use-start`：`startTime`（缺则 `createdAt`），MUST NOT 用 `endTime` 作间隔/`lastAt` 锚点。
- **不做**：显式双峰聚类产品化（B）、经验日末分位数产品化（C）——本 change 仅 A + D 直方图。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `event-interval-prediction`：间隔时段投票由 6 桶阶梯改为钟点连续亲和加权；增加基于历史钟点直方图的 `nextAt` 冷区护栏与拒绝后回退。

## Impact

- 代码：`app/lib/data/event_next_predictor.dart`（及调用方若依赖桶 API）；预测页 / 小组件 / pending 间接触达 `nextAt`。
- 规格：对照并改写基线 `event-interval-prediction` 中同档/相邻/全桶 Scenario；基线 `openspec/specs/v2.1.4.md`，并与 `predict-interval-use-start` 的 start 锚点对齐。
- 无 Android/iOS 原生、无 Go API 契约变更。
