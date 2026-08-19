# Proposal: 横屏可调列数与卡片 scale

## 背景

横屏预测页瀑布列数目前写死（手机 3、平板 5），卡片内 logo/字号/Switch 等为固定 magic number。宽屏投屏或事件较多时，用户无法自行调节密度。

## 目标

- 横屏左栏月龄下方增加 `[−] n [+]` 步进器，调整每行事件列数（1–7），持久化；无手动输入。
- 手机首次默认 3 列、平板首次默认 5 列；步进器手机/平板 landscape 共用。
- 引入 `PredictionLandscapeCardMetrics`：按单元格宽度相对基准列宽等比缩放 compact 卡内字体、logo、Switch、间距；hero logo 随 scale 缩小，不强制改侧 logo 策略。
- 竖屏仍为 2 列，不受影响。

## 非目标

- 不设 scale 下限或 7 列可用性兜底；用户自行调节。
- 不改变竖屏 list/grid 切换与 `landscape-phone-trailing-inline-logo` 行规则。

## 规格影响

- `smart-prediction-page`：MODIFIED 横屏固定列数 → 可调列数 + scale 卡片。
