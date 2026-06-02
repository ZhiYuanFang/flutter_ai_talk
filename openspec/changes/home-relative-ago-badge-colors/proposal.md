## Why

主页历史时间轴中，各事件最新记录下方的相对时间标签（如「12分前」）当前使用 `onShell` 中性前景色作为背景与文字，与同行事件圆点、Logo 所使用的事件 accent 色脱节，在彩色 shell 主题上显得发灰、不协调。需要将标签配色改为跟随行内事件 accent，以提升视觉一致性与可读性。

## What Changes

- 相对时间标签**背景色**改为 `ColorScheme.primary`，透明度 **0.3**
- 相对时间标签**文字色**仍为行内 event accent 向红色偏移后的色值
- 无有效事件品牌色时继续回退 `ColorScheme.primary`（与现有 `resolveEventColor` 行为一致）
- 标签布局、文案格式、展示条件、分钟级刷新逻辑**不变**

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-history-relative-ago-badge`：更新「相对时间标签主题样式」需求——色源由 shell 前景语义色改为行内 event accent；背景不透明度由 0.2 改为 0.3；文字色改为 accent 偏红衍生色

## Impact

- **代码**：`app/lib/ui/home_history_timeline_tile.dart`（badge 装饰与文字样式，约 10 行）
- **规格**：`openspec/specs/home-history-relative-ago-badge/spec.md`（样式需求 delta）
- **API / 数据**：无
- **依赖**：无新增
