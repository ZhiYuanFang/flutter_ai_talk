## Context

预测页 tip / 留意壳 / 事件卡用手拼 `contentCard + tertiary/primary` 渐变；暗壳 `contentCard` 近白，chrome 发白、字对比差。用户选定 **A（统一 panelGlass 渐变）+ B（可选 accent）**，且暗壳应从「稍浅主题色」起笔而非白。

## Goals / Non-Goals

**Goals:**

- 新增 `panelGlass*` 原子与 `panelGlassGradient(accent?)`。
- 暗壳 top ≠ contentCard 近白；配对 `textOnPanelGlass`。
- 预测页三处改挂；事件卡传 accent。

**Non-Goals:**

- 不改 Feed `contentCard` 浅卡策略。
- 不强制全仓所有渐变立刻迁入（本 change 以预测页为主；其它可后续跟进）。
- 不新建测试文件。

## Decisions

### D1：角色分离

```
contentCard  → Feed/历史列表内容块（暗壳可浅）
modal*       → Dialog / 软引导浮层
panelGlass*  → 页内 chrome（tip、留意条、预测卡外壳）
```

### D2：派生（A）

| 字段 | 浅壳 | 暗壳 |
|------|------|------|
| `panelGlassTop` | `alphaBlend(primary@~0.18, contentCard或surface)` | `alphaBlend(seed/primary@~0.22–0.28, surface)`，可再 HSL 略提亮；**禁止** L≈0.94 contentCard 作 base |
| `panelGlassBottom` | 近 `fieldFill` | `surface` 或略深于 top 的同系叠色 |
| `onPanelGlass` | `_readableOn(top)` | 同（通常为浅字） |

`AppColor.panelGlassGradient` 默认 `LinearGradient(topLeft→bottomRight, [top, bottom])`。

### D3：可选 accent（B）

`panelGlassGradient(context, {Color? accent})`：  
- `accent == null` → 用 theme primary/seed 参与 top 叠色。  
- 非 null → 用 accent 替代强调叠色（事件品牌例外），α 仍在原子内。

### D4：字色

面板内正文/标题 MUST 用 `textOnPanelGlass`（或 muted 变体），MUST NOT 在近亮错误底上继续用 `textPrimary`/`onShell` 导致不可读。

### Alternatives considered

- 把 contentCard 改暗：破坏 Feed。否决。  
- 仅改预测页本地色：达不到全局原子。否决。

## Risks / Trade-offs

- [浅壳观感变一点] → top 仍偏浅玻璃，矩阵验收经典主题。  
- [accent 过艳] → α 封顶（如 ≤0.22）。  

## Migration Plan

- 纯客户端。回滚：恢复手拼渐变。  

## Open Questions

- （无）A+B 与暗壳主题色起笔已确认。
