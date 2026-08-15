## Why

预测横屏护眼当前用 `deriveDarkBundle` 把粉彩浅 seed 的明度夹死到同一暗区，导致不同浅色 preset / 不同浅色程度在横屏上看起来几乎同色，违背「保留主题气质」的预期。需要改为横屏专用「TV 压暗」：降低刺眼亮度，但仍像竖屏那套浅色色感，且不同浅色彼此可辨。

## What Changes

- 横屏浅壳路径 **不再** 调用 `deriveDarkBundle` 作为护眼配方（该 API 仍可供其它暗壳场景使用）。
- 新增横屏专用压暗派生：在**当前浅色 VisualBundle / seed 气质**上压低壳与玻璃亮度，保留色相与相对深浅差异；字色/panel 对比仍可读、投屏不刺眼。
- 已暗壳主题仍透传；回竖屏立即恢复原主题、不写 baseline；一体覆盖身份栏 / chip / 弹幕等既有挂载方式保留。
- 规格从「强制暗壳 `isDarkShell`」调整为「TV 压暗且可区分浅色身份」（实现上可为暗壳 tokens 或明确文档化的压暗浅壳，以观感为准）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-landscape-tv-safe-theme`：横屏护眼由「强制 `deriveDarkBundle` 暗壳」改为「保留浅色气质的 TV 压暗」；不同浅色程度 / 色相在横屏 MUST 可辨。

## Impact

- 代码：`landscapeTvSafeThemeOf`（及可能的 `deriveLandscapeTvDimBundle`）；`smart_prediction_screen` 挂载点可不变。
- 不改主题持久化、自动夜空、竖屏主题。
- 测试：不新建 `**/test/**`；手工多浅色 preset × 横屏对比验收。
