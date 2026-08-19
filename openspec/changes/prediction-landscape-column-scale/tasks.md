## 1. 存储与 metrics

- [x] 1.1 新增 `PredictionLandscapeColumnStore` + `predictionLandscapeColumnProvider`（1–7，无存档默认由 UI 按 3/5）
- [x] 1.2 新增 `PredictionLandscapeCardMetrics`（cellWidth 基准 scale + 基准尺寸表）

## 2. UI 接线

- [x] 2.1 扩展 `_PredictionLandscapeIdentityRail`：月龄下 `[−] n [+]` 步进器
- [x] 2.2 横屏 `waterfallColumns` 读有效列数；`LayoutBuilder` 算 metrics 传入 `_PredictionEventCard`
- [x] 2.3 `_PredictionEventCard` compact 路径用 metrics 替代硬编码尺寸；`_WaterfallCards` 支持缩放 gap
- [x] 2.4 横屏左栏昵称上方展示 `BabyAvatar`（可点进设置，与竖屏顶栏一致）
- [x] 2.5 列数控件改为左栏底部纵向密度轨（真拖；上少列/下多列；3–7；无数字；月龄尾部省略防越界）
- [x] 2.6 密度轨移至右缘：竖排「拖动调整大小」+ 拉满至屏底；左栏仅身份
- [x] 2.7 横屏三栏 Row：左身份 | 中事件（Expanded）| 右密度轨，事件区不得盖住拖动区
- [x] 2.8 预测卡 header 两行布局：事件名与 Switch 同行；Switch 列宽 `52×switchScale`；第二行超时+开关文案右对齐（右缘=Switch 右缘），单行尾部省略
- [x] 2.9 预测卡圆角 `18×scale`（ClipRRect / BoxDecoration / InkWell 三处一致）

## 3. 校验

- [x] 3.1 `dart analyze` 触及文件无新增 error
- [ ] 3.2 手工：手机默认 3、平板默认 5、拖动密度轨 3/7 边界、7 列不溢出、竖屏无控件
