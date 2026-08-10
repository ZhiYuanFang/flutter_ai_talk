## 1. 浅色 panelGlass 同构

- [x] 1.1 在 `VisualBundle.toTokens()` 浅色分支改为近白 glass base + seed 淡染，bottom 更浅；不再用满色 recordsCard/surface 作玻璃底
- [x] 1.2 （已修正范围）panelGlass 近白配方保留

## 2. 暗壳 accent 与夜空同构

- [x] 2.1 为 `deriveDarkBundle` 派生偏亮 chrome `seedColor`
- [x] 2.2 夜空固定 `kNightSky*`；暗壳 panelGlass α 共用

## 3. 自定义浅色（设置「彩色」）与经典同构

- [x] 3.1 抽出与经典同构的 `lightTintedBundle(seed)`（白+seed@0.08 壳 / @0.04 surface）
- [x] 3.2 `resolveVisualBundle` 浅色自定义改为 `lightTintedBundle`；`classicLightBundle` / `lightSwatchBundle` 共用该 helper
- [x] 3.3 手动确认：经典 ↔ 设置「彩色」自定义浅色留意/广场观感同构（近白淡染+玻璃渐变）
