## 1. 公用主题 Sheet

- [x] 1.1 抽出 `showThemePaletteSheet` / 共享 Sheet：经典·夜空·彩色、色盘默认展示、自动夜空；复用 persist 与 `refreshScheduledTheme`
- [x] 1.2 改自定义色时自动选中「彩色」；自动夜空开启时禁用可用自定义选色

## 2. 主壳三页入口

- [x] 2.1 `ThemePaletteIconButton`（或等价）；喂养 header：趋势左侧、调色盘最右
- [x] 2.2 预测顶栏最右挂同一按钮；UCG 主壳可见顶栏 actions 最右挂同一按钮

## 3. 设置拆除

- [x] 3.1 设置页移除主题区块（预设 + 自动夜空行），避免双入口

## 4. 验收

- [x] 4.1 手动确认：三页打开同一 Sheet；默认见色盘；改色选中彩色；自动夜空开则不可自定义；设置无主题块
