## 1. 主题派生

- [x] 1.1 提供「由当前 seed 生成暗壳 ThemeData」的入口（复用 `deriveDarkBundle` + 与 `buildAppTheme` 同构 tokens/`ColorScheme`；浅 seed MUST 不误入 `lightTintedBundle`）
- [x] 1.2 确认不写 `ThemePreferences` / 不改自动夜空 baseline

## 2. 预测页挂载

- [x] 2.1 在 `SmartPredictionScreen` 横屏时用 `Theme` 包裹页内子树（含身份栏、瀑布流、chip、弹幕 toast）；竖屏不覆盖
- [x] 2.2 全局已暗壳时透传或等价暗壳，避免浅壳残留；回竖屏立即恢复祖先 Theme

## 3. 验收

- [ ] 3.1 手工：浅色 preset / 彩色种子 × 预测横屏 → 暗壳且 tint 可辨；弹幕+chip+身份栏一体不刺眼
- [ ] 3.2 手工：回竖屏 / 夜空主题横屏 → 立即恢复或保持暗壳；设置中 baseline 未变
