## Context

`buildAppTheme` 已用设置种子/`AppVisualTokens` 驱动 `ColorScheme.primary` 与 shell。问题在业务层仍按「浅色玻璃」写死 `Colors.white`/`black54`。用户确认范围 **P0 + P1**；P2 全局扫尾另议。

## Goals / Non-Goals

**Goals:**

- 固化主题色使用规范并写入 `openspec/project.md`。
- P0：绑定页按钮字色、UCG 主列表字色、Feed 假玻璃暗壳不偏白。
- P1：绑定页其余玻璃、宝宝资料黏土主题、预测引导卡玻璃随主题。
- 提供可复用的暗/浅玻璃叠色 helper，避免各页各自 `alphaBlend(white)`。

**Non-Goals:**

- P2 全仓硬编码清零与 custom_lint。
- 不改事件品牌 `colorHex`、媒体封面遮罩语义。
- 不新建 `**/test/**`。

## Decisions

### D1：规范五条（规范性摘要）

1. 业务色 MUST 来自 `colorScheme` 或 `AppVisualTokens`（及本仓库主题 helper）。  
2. MUST NOT 用 `Colors.black54` / 固定灰阶作正文或次要按钮前景。  
3. 半透明叠色 MUST 随主题；暗壳 MUST NOT 大面积 `Colors.white` α≥约 0.5 作卡片/面板底。  
4. 高对比白字仅允许压在深色强调底（如 `primary` 实心钮）上，并优先 `onPrimary`。  
5. 例外（事件色、媒体遮罩、SDK）须注释标明。

### D2：玻璃 helper（建议放 `app_theme_scope.dart` 或 `app_visual_tokens` 旁）

| Helper | 浅壳 | 暗壳 |
|--------|------|------|
| `themeGlassFill` | 低/中 alpha 白叠 `recordsCard`/`surface` | `surface`/`recordsCard` + 低 alpha `primary`，无高 alpha 白 |
| `themeGlassBorder` | 白边低～中 alpha | `surfaceBorder` 或 `onShell` 低 alpha |
| `themeMutedForeground` | `onShell`/`onSurface` α≈0.55 | 同左（禁 `black54`） |
| `themeEmphasisOnFill` | `onPrimary` | `onPrimary` |

`UcgFeedFakeGlassPanel`、绑定玻璃、预测引导卡共用上述 API。

### D3：P0 触点

- `baby_bind_screen`：取消 → `themeMutedForeground`；确认前景 → `onPrimary`（底可仍 `primary`）。  
- UCG：主 Feed 列表/moments 中仍硬编码或对比错误的正文 → `onShell` / `ucgFeedFakeGlassTextColor` 等；扫 `ucg/ui` 主路径高流量字色。  
- `UcgFeedFakeGlassPanel`：`fillTop`/`border` 改走 glass helper；`ucgFeedFakeGlassBorderColor` 同步。

### D4：P1 触点

- `baby_bind_screen` 其余 `Colors.white` 玻璃块（选中描边、输入壳等）按 `isDarkShell` 换 helper。  
- `baby_profile_clay_theme`：固定 `cardColor`/`textPrimary` 等改为随 `shell`/`onShell`/`surface` 推导（保留性别芯片语义色可例外注释）。  
- `_PredictionAuthGateCard`：白边与渐变白叠改 glass helper。

### D5：验收矩阵

手工：经典 | 自定义浅色 | 夜空 × 绑定页 | UCG Feed | 预测引导 Dialog。暗壳下卡片不得呈「白板」，取消钮不得发黑灰不可读。

## Risks / Trade-offs

- [黏土页改色破坏「黏土」识别] → 浅壳尽量保留暖灰推导；暗壳降饱和跟 shell。  
- [UCG 马卡龙辩论色] → 保留品牌渐变例外；仅改假玻璃底与通用正文。  
- [漏扫] → P0/P1 列明文件；P2 另开。

## Migration Plan

- 纯客户端。回滚：恢复硬编码白/灰。  
- 规范写入 project.md 后，后续 change 默认遵守。

## Open Questions

- （无）范围已定为 P0+P1。
