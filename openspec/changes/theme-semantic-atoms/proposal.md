## Why

设置主题色已能驱动 `ColorScheme` / `AppVisualTokens`，但业务组件仍各自 `if (isDarkShell)`、手写 alpha 白叠或混用 `onShell` 与浅色 `recordsCard`，导致夜空下预测引导卡「浅蓝底 + 白字」不可读、同类浮层/页面色不一致。需要把「随主题变化的颜色」收成全局语义原子：组件只选角色，派生逻辑只活在原子层。本变更一次性完成 Phase 0–3（目录与契约 → 统一容器 → 高频迁入 → 清扫拼色）。

## What Changes

- **语义原子目录**：在主题派生层提供统一角色（至少：`pageBg`、`textPrimary`/`textSecondary`/`textMuted`、`surface`/`textOnSurface`、`contentCard`/`textOnContentCard`、`modalFill`/`textOnModal`/`modalBorder`、`sheetFill`/`textOnSheet`（可与 modal 同源）、`fieldFill`/`fieldBorder`、`primary`/`onPrimary`、`divider`、`barrier`），由 `VisualBundle.toTokens()`（或等价）一次算完；半透明 α 封在派生内。
- **组件契约**：`app/lib/ui/**`、`app/lib/ucg/**` 业务色 MUST 只经原子 API / 语义 token 取色；MUST NOT 为拼色读取 `isDarkShell` 或散落 `Colors.black54` / 高 alpha 白底；**例外**仅事件品牌色、媒体遮罩、第三方 SDK（须注释）。
- **Modal 暗浮层（产品已选 B）**：暗壳下通用 Dialog / 软引导浮层底为 `surface`（+ 低 alpha primary）系，字为 `onShell`/`textOnModal`；MUST NOT 再拿浅色 `contentCard`/`recordsCard` 当 Dialog 底却配白字。
- **统一容器**：`showGlassDialog` / 确认 Dialog、预测登录·绑定引导卡、召回类软浮层挂同一 modal 原子（或共享 `AppModalPanel`）；`HistoryEditGlassPanel` 等玻璃容器去掉写死 hex，改走原子（事件 accent 仍可注入）。
- **高频迁入**：绑定、UCG 主列表/Feed、设置、预测页等改用 `pageBg`/`text*`/`contentCard*`/`modal*`。
- **清扫**：仓内业务 UI 清除为拼色而用的 `isDarkShell` 分支与死 hex（保留合法例外注释）；`openspec/project.md` 主题色约定升级为「原子优先」。
- **承接**：`theme-tokens-dark-shell-audit` 的 helper/规范为前传；本 change 将其升格为正式原子体系并完成全仓 Phase 0–3。不新建 `**/test/**`。

## Capabilities

### New Capabilities

- `theme-semantic-atoms`：语义原子目录、组件禁判契约、modal/contentCard 角色分离、以及 Phase 0–3 验收场景。

### Modified Capabilities

- `app-visual-tokens`：扩展/对齐语义字段与派生义务（modal/content 角色及可读配对）。
- `home-history-edit-sheet-glass-visual`：玻璃编辑容器 MUST 使用主题语义原子，不得写死单一深色 hex 底板/前景而不跟主题派生。

## Impact

- **主题核心**：`app/lib/theme/app_visual_tokens.dart`、`theme_preset.dart`、`app_theme_scope.dart`（原子 API / 旧 helper 薄封装或弃用路径）。
- **统一入口**：`app/lib/ui/widgets/app_glass_overlay.dart`、`home_history_edit_glass_panel.dart`、`ucg_compose_light_glass_panel.dart`、预测引导/召回浮层。
- **高频 UI**：`smart_prediction_screen.dart`、`baby_bind_screen.dart`、UCG Feed/广场、设置与黏土编辑相关页。
- **文档**：`openspec/project.md`「主题色约定」改为原子契约；与未归档的 `theme-tokens-dark-shell-audit` 衔接（实现时可先归档或合并理解）。
- **验证**：手工矩阵 经典 / 自定义浅色 / 夜空 × 页面底·正文·Dialog·Feed 卡·绑定·预测门禁；`dart analyze` 触达文件无 error。
