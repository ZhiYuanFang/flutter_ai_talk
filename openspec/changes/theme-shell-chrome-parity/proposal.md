## Why

设置「彩色」是自定义浅色 seed（非整页 soft swatch 预设）。自定义浅色曾把选色直接当 `shellColor`，BackdropFilter 把满色页底灌进留意/广场玻璃，与经典（近白壳 + seed 染料）观感分裂，无法一处调色。暗壳自定义与夜空亦需同构。

## What Changes

- **彩色（自定义浅色）**：bundle 与经典同构——`seedColor` = 选中色（染料）；`shellColor` = 白 + seed@0.08；`surfaceColor` = 白 + seed@0.04。禁止浅色自定义把选色直接当满色页底。
- 浅色 `panelGlass*`：近白 glass base + seed 淡染，bottom 更浅（已落地，保持）。
- soft swatch 若仍可达：同样走近白壳 + seed 染料，与经典/自定义浅色同构。
- 暗壳：非夜空 `deriveDarkBundle` 派生偏亮 chrome `seedColor`；夜空固定 hex 不动（已落地，保持）。
- 不强制事件卡 `accent:` 叠色第二步。

## Capabilities

### New Capabilities

- `theme-shell-chrome-parity`：经典↔自定义浅色（设置「彩色」）、暗壳夜空↔其它暗壳的 chrome/页底结构同构。

### Modified Capabilities

- `app-visual-tokens`：浅色自定义 seed MUST 近白壳+染料；深色推导分离页底与亮 accent。

## Impact

- `theme_preset.dart`：`resolveVisualBundle` 浅色自定义分支；抽出与经典同构的 light tinted helper；soft swatch 对齐。
- 观感：选「彩色」换色相后留意/广场接近经典玻璃；页底为淡染近白而非满色铺底。
