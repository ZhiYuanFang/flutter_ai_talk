## 1. 相对时间标签配色

- [x] 1.1 在 `home_history_timeline_tile.dart` 中为 badge 定义文字偏红常量（lerp 目标 `#E53935`、比例 0.15）
- [x] 1.2 将 badge 背景改为 `ColorScheme.primary.withValues(alpha: 0.3)`（主题色，非 event accent）
- [x] 1.3 将 badge 文字色改为 `Color.lerp(accent, warmRed, 0.15)`，移除 badge 段对 `onShell` 的依赖
- [x] 1.4 确认字号、圆角、内边距、槽位高度与变更前一致

## 2. 验证

- [x] 2.1 在至少两种 shell 主题下目视：badge 背景为主题 primary @0.3、文字为 event accent 偏红可读
- [x] 2.2 确认无品牌色事件回退 primary 时 badge 仍正常着色
- [x] 2.3 确认进行中计时不展示标签、分钟 tick 文案仍更新（行为无回归）
