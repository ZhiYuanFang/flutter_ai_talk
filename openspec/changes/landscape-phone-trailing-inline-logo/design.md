## Context

手机横屏 3 列瀑布流按 `index % columnCount` 分列。产品更正：紧凑侧 logo 针对 **第二行及以后**，不是第二列及以后。平板不动。

## Goals / Non-Goals

**Goals:**

- 手机横屏：视觉第一行（每列第 0 张）大 logo；其后各行标题旁小 logo。
- 平板 / 竖屏不变。

**Non-Goals:**

- 不改列数、身份栏、语音。
- 不改平板布局。

## Decisions

1. **设备门控**  
   `phoneLandscape = landscape && shortestSide < 600`。

2. **行判定（更正后）**  
   `_WaterfallCards` 对每列调用 `itemBuilder(row, columnIndex, rowIndexInColumn)`，或传 `isFirstRowInWaterfall`。  
   `titleInlineLogo = phoneLandscape && rowIndexInColumn > 0`。  
   **否决**：`columnIndex > 0`（旧误解）。

3. **布局分支**  
   同前：`showTitleLogo` / `showHeroLogo` 由 `titleInlineLogo` 驱动。

4. **心跳 / 锚点**  
   挂在可见 logo。

## Risks / Trade-offs

- [瀑布流各列高度不齐，「第一行」不完全齐平] → 仍以「每列第 0 张」为第一行定义，与分列算法一致。  
- [已按列实现的代码] → apply/修正时改判定即可。

## Migration Plan

1. 更新判定：列内 `rowIndex > 0`。  
2. 手机横屏验收：顶行三张大图，下方侧 logo。  
3. 平板不变。

## Open Questions

- （无）「第一行 = 每列顶部第一张」已按更正采纳。
