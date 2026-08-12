## Context

预测页横屏与竖屏共用全局 `MaterialApp` 主题（`buildAppTheme` + `AppVisualTokens`）。浅色 preset / 自定义浅色在大屏投屏时壳亮度过高。工程约束要求业务色经 `AppColor` / tokens；主题层已有 `deriveDarkBundle(Color seed)` 可将任意种子压成暗壳且保留 seed 染料。

用户拍板：横屏一律暗（A）；保留当前 preset 主色 tint；弹幕 / chip / 身份栏一体；回竖屏立即恢复原主题；不改持久化 baseline。

## Goals / Non-Goals

**Goals:**

- 预测页 `Orientation.landscape` 时，页内子树强制暗壳 `ThemeData`（含 `AppVisualTokens`），使壳、卡、身份栏、语音 chip、弹幕 toast 等经 `AppColor` 取色的 chrome 一致变暗。
- 暗壳 MUST 由当前生效主题的 **seed / 主色 tint** 经既有暗壳配方派生（优先复用 `deriveDarkBundle`），不得硬编码无关夜空色。
- 竖屏或离开横屏条件时，子树取消覆盖，立即呈现全局原主题。

**Non-Goals:**

- 不改用户设置里的主题 baseline、自动夜空持久化逻辑。
- 不新增「投屏/护眼」开关。
- 不改竖屏预测、其它路由横屏、喂养/广场。
- 不新建 `**/test/**`。
- 不单独重写弹幕思考脉冲等既有行为（仅随 tokens 变暗）。

## Decisions

### D1：覆盖点 = 预测页横屏子树 `Theme`

在 `SmartPredictionScreen`（或紧裹其 scaffold/body 的父级）当 `isLandscape` 时包一层 `Theme(data: tvSafeTheme, child: …)`，覆盖范围覆盖身份栏、瀑布流、chip、弹幕与同页其它 chrome。

| 备选 | 为何不选 |
|------|----------|
| 全局切换 `themeProvider` | 会污染其它 Tab，且易误写 baseline |
| 仅叠 scrim | 发灰、字色仍按浅壳算，对比差 |
| 业务内逐控件改色 | 违反 AppColor 纪律、易漏 |

竖屏：不包覆盖（或 `Theme` 回退为 `Theme.of(context)` 祖先）。

### D2：一律暗 + 保留 tint → `deriveDarkBundle(currentSeed)`

1. 从当前生效主题读取 `AppVisualTokens.seedColor`（或等价 VisualBundle seed；经典浅色用现有 `resolveVisualBundle` 同源种子）。
2. `final darkBundle = deriveDarkBundle(seed)`（已有 API：`isDarkShell: true` + seed tint）。
3. `ThemeData` 经与 `buildAppTheme` 同构路径生成（可抽 `buildAppThemeFromBundle` 或临时 `buildAppTheme(preset: null, customBackground: seed)` 在暗 luminance 路径上走 `deriveDarkBundle`——实现时优先**显式**调用 `deriveDarkBundle`，避免浅 seed 误入 `lightTintedBundle`）。
4. 若全局已是暗壳：仍可用同一派生（视觉近似 no-op）或直接透传祖先 Theme；推荐透传已暗壳以减少重建，但 MUST 保证浅→横屏一定变暗。

### D3：种子来源与 sex primary

- soft / 彩色自定义：用 tokens `seedColor`。
- 经典浅色：`classicLightBundle` 的 seed（含性别 primary 逻辑）经 `buildAppTheme` 现有 `_resolveThemePrimary` 同构；暗化后 primary 仍走暗壳分支。
- 夜空：已暗，透传即可。

横屏覆盖 **不得** 调用写盘的 theme persist API。

### D4：一体范围

MUST 落在覆盖子树内：页壳、事件卡、身份栏、landscape voice chip、subtitle toast、同页 tip/timeline 等已用 `AppColor` 的控件。

Overlay / `showDialog` 若使用 root navigator 且脱离子树 Theme，则门闸 Dialog 可能仍浅色——本变更 P0 以页内 chrome 为准；若门闸在横屏常见路径且明显刺眼，实现时尽量用继承子树 Theme 的方式呈现（或列为 follow-up）。

### D5：生命周期

```
竖屏 / 非预测     → 全局 Theme
进入预测横屏     → 子树暗壳 Theme（seed tint）
回竖屏 / 离开页  → 去掉覆盖，立即恢复全局 Theme
```

与现有沉浸式 SystemChrome / wakelock 条件对齐：`isLandscape && predictionPageVisible`（实现时与 immersive 同一判定，避免不同步）。

## Risks / Trade-offs

- [横屏旋转 Theme 重建闪一下] → 可接受；避免额外动画强行淡入。
- [Dialog/Overlay 仍浅] → P0 页内一体；门闸若刺眼再跟进。
- [seed 提取错误导致 tint 丢失] → 单测手工：softPink / 彩色 / 经典 × 横屏，主色可辨。
- [与自动夜空叠加] → 横屏只读当前已生效 Theme 的 seed；不写 baseline。

## Migration Plan

- 纯客户端。回滚：移除横屏 `Theme` 覆盖即可。

## Open Questions

- （无）强度 / 范围 / tint / 恢复策略已由用户确认。
