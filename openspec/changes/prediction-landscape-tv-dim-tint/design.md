## Context

`prediction-landscape-tv-safe-colors` 已在预测横屏挂 `Theme` 覆盖，但浅壳路径误用 `deriveDarkBundle`：粉彩 seed 明度被夹到 0.10–0.16，不同浅色横屏几乎同色。用户选定纠偏方向 **D**：横屏专用 TV 压暗，贴近竖屏浅色气质，不强制夜空式暗壳配方。

## Goals / Non-Goals

**Goals:**

- 替换 `landscapeTvSafeThemeOf` 浅壳分支：用 **TV 压暗 bundle** 替代 `deriveDarkBundle`。
- 不同浅色 preset / 自定义浅色 / 不同浅色程度在横屏壳色上 **可辨**（色相与相对深浅）。
- 压暗后投屏不刺眼；字色经 tokens/`AppColor` 可读；挂载范围与回竖屏行为不变。

**Non-Goals:**

- 不改 `deriveDarkBundle` 对其它调用方的语义（仅横屏护眼停用）。
- 不改竖屏主题、持久化、自动夜空。
- 不重做芯片/弹幕交互。

## Decisions

### D1：压暗对象 = 浅色 bundle 的 shell/surface（不是把 seed 压成夜空）

竖屏浅色差异体现在 `lightTintedBundle` 的近白壳淡染。对 **shell/surface** 做黑叠或等比降亮，粉/蓝/黄的相对差会保留；对粉彩 seed 做 `deriveDarkBundle` 则会抹平。

```
lightBundle.shell  --TV dim-->  略暗但仍带 seed 染料的壳
lightBundle.seed   ----------->  仍作 primary / accent 染料（可略加饱和以便可读）
```

### D2：配方（实现常量可微调）

建议 `deriveLandscapeTvDimBundle(VisualBundle light)`：

1. `shell = alphaBlend(black@~0.40–0.48, light.shellColor)`
2. `surface = alphaBlend(black@~0.28–0.36, light.surfaceColor)`
3. `seedColor` 沿用 `light.seedColor`（保留 tint 来源）
4. `isDarkShell`：按压暗后 `shell.computeLuminance()` 与现有 `_darkLuminanceThreshold`（0.25）判定，使 `toTokens`/`onShell` 对比正确——**允许**结果为「偏暗的浅壳路径」或「轻度暗壳」，以可读为准，不强制夜空 L≈0.12
5. `buildAppThemeFromBundle(dimmed, sex)` 生成 Theme

已暗壳：继续透传 `current`。

### D3：挂载点不变

仍仅改 `landscapeTvSafeThemeOf`；`SmartPredictionScreen` 的 `Theme` 包裹逻辑保持。

### D4：验收标准（观感）

| 对比 | 期望 |
|------|------|
| softPink vs softBlue 横屏 | 壳色明显不同 |
| 同色相更浅 vs 略深自定义浅色 | 横屏仍有相对深浅差（不完全同色） |
| 相对竖屏 | 明显更暗、不刺眼，但仍像「压暗的该主题」而非统一灰黑 |

## Risks / Trade-offs

- [压暗不够仍刺眼] → 调高黑叠 alpha；验收时电视/投屏看一眼。
- [压暗过度又变「同色」] → 黑叠勿超过 ~0.55；禁止再夹死到固定 L。
- [isDarkShell 临界闪字色] → 用 luminance 阈值，避免手写死 false。

## Migration Plan

- 纯客户端。回滚：浅壳分支恢复 `deriveDarkBundle`（不推荐）。

## Open Questions

- （无）方向 D 已确认；具体 alpha 实现时按验收微调。
