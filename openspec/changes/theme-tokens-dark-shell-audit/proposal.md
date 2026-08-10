## Why

设置主题（尤其夜空/暗壳）下，业务 UI 仍大量硬编码浅色玻璃白与灰阶字色，导致绑定页取消钮、UCG 正文与动态卡片在暗色系呈「白板/脏灰」，与 `ColorScheme` + `AppVisualTokens` 脱节。需要先立规范，再按 P0/P1 修已知突兀面与邻近玻璃/黏土页。

## What Changes

- **立规范**：业务 UI 优先 `Theme.of(context).colorScheme` + `AppVisualTokens`；禁止散落硬编码品牌/正文色；半透明叠色须主题化；暗壳（`isDarkShell`）禁止大面积高 alpha 白底导致突兀。
- **文档**：将规范摘要写入 `openspec/project.md`（或等价工程约定），供后续变更遵守。
- **P0 修复（已知病灶）**  
  - 宝宝绑定页：取消/确认按钮字色与主题前景对齐（去掉 `Colors.black54` / 死白字硬编码）。  
  - UCG 广场主列表：正文/次要文字统一走 `onShell` / `onRecordsCard` / scheme，暗壳可读。  
  - 动态卡片：`UcgFeedFakeGlassPanel`（及边框/文字 helper）暗壳不再高 alpha 白底。
- **P1 修复（邻近玻璃/黏土）**  
  - `baby_bind_screen` 其余玻璃白叠色；`baby_profile_clay_theme` / 编辑页固定浅色板改为随 shell/tokens。  
  - 预测页登录/绑定引导卡白边与玻璃叠色随主题（含暗壳）。
- **P2 不在本 change**：其余仓内 `Colors.white` 扫尾与 lint 禁新增（可另开 change）。

## Capabilities

### New Capabilities

- `theme-color-governance`：主题色使用规范、暗壳玻璃叠色约束、以及本 change 覆盖面的验收场景。

### Modified Capabilities

- （无独立旧 capability 名；行为落在绑定/UCG Feed/预测引导等既有页面，以本规范 spec 场景验收。）

## Impact

- **主题**：可新增暗壳玻璃 helper（如 `glassFill` / `glassBorder` / `mutedForeground`），复用 `isDarkShell`、`recordsCardColor`、`onShell`、`primary`。
- **UI**：`baby_bind_screen.dart`、`baby_profile_clay_theme.dart` / `baby_profile_editor.dart`、`ucg_feed_fake_glass_panel.dart`、UCG 列表相关 widgets、`smart_prediction_screen.dart` 引导卡。
- **文档**：`openspec/project.md` 增「主题色约定」小节。
- **测试**：不新建 `**/test/**`；手工矩阵：经典浅色 / 自定义浅色 / 夜空暗壳 × 绑定 / UCG Feed / 预测引导。
