## Context

相对时间标签由 `HomeHistoryTimelineTile` 在 `showRelativeAgo == true` 时渲染，位于历史行下方，文案形如 `[12分前]`。当前实现（约 229–257 行）使用 `AppVisualTokens.onShell` 作为背景（alpha 0.2）与文字色。同一 `build()` 内已通过 `resolveEventColor(context, event)` 得到 `accent`，用于时间轴圆点与 EventLogo 光晕。

基线规格见 `openspec/specs/home-history-relative-ago-badge/spec.md` 中「相对时间标签主题样式」：要求主题语义色、背景不透明度 0.2。

## Goals / Non-Goals

**Goals:**

- 标签**背景**跟随应用主题色 `ColorScheme.primary`（alpha **0.3**）
- 标签**文字**跟随行内 event accent 向红色偏移的衍生色
- 切换 shell 主题时背景随 primary 更新；更换事件品牌色时文字随 accent 更新

**Non-Goals:**

- 不改标签展示条件、文案格式、布局尺寸、分钟 tick
- 不新增全局主题 token 或设置项
- 不为极端浅色事件色做首版专项 contrast 分支（除非实机不可读再迭代）

## Decisions

### 1. 背景：主题 primary @ alpha 0.3

**选择**：`Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)`。

**理由**：背景随全局主题统一，换主题时所有 badge 一致；不与各行 event accent 绑定。

### 2. 文字：行内 event accent 向红 lerp

**选择**：复用 `resolveEventColor` 得到的 `accent`，`Color.lerp(accent, #E53935, 0.15)` 作为文字色。

**理由**：文字仍标识「该事件」的时效信息，与圆点/Logo 色系呼应；背景与文字分层。

### 3. 不引入 isDarkShell 分支

**选择**：首版统一公式，不在 `AppVisualTokens.isDarkShell` 上分支。

**理由**：变更范围极小；主题 primary 背景 + event accent 文字在深浅 shell 上通常可读。

**实现位置**：`home_history_timeline_tile.dart` 内 private 常量 + lerp；背景取 `colorScheme.primary`。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 极浅 event accent 上文字对比不足 | 实机扫 2–3 个浅色自定义事件；必要时对高 luminance accent 略降文字 lightness |
| 0.3 背景在浅色 shell 上偏淡 | 文字仍用 event accent 偏红保可读；必要时微调 alpha |
| 绿/蓝 accent lerp 红后略「脏」 | 15% 为保守值；可调到 10–12% |

## Migration Plan

- 单文件 UI 改动，无数据迁移
- 热重载即可验证；回滚为恢复 onShell 配色

## Open Questions

（无 — 背景为主题 primary @0.3；文字为 event accent 偏红。）
