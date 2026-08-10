## Why

`theme-semantic-atoms` 已提供 `contentCard` / `modal` / `field` 等角色，但智能预测页 tip、留意壳、事件卡仍在业务里手拼 `alphaBlend(tertiary/primary, contentCard) → fieldFill`。暗壳下 `contentCard` 为近白浅卡，导致页内 chrome「白太多、字看不清」。需要把**页内玻璃面板**升为独立原子（与 Feed 浅卡、Dialog 浮层分离），并支持可选事件强调色。

## What Changes

- **新增角色 `panelGlass*`**：`panelGlassTop` / `panelGlassBottom` / `textOnPanelGlass`，以及 `AppColor.panelGlassGradient(context, {Color? accent})`（A 统一渐变 + B 可选 accent）。
- **暗壳派生**：渐变起点 MUST 为略亮于 shell/surface 的主题色叠色，MUST NOT 以近白 `contentCard`（L≈0.94）起笔；配对前景 MUST 用 `textOnPanelGlass`。
- **浅壳**：可继续浅玻璃观感（content/surface + 低 alpha primary），字色配对可读。
- **迁入**：`smart_prediction_screen` 中 tip 条、留意壳、预测事件卡外壳改挂 `panelGlass*`；事件卡传 `accent: eventColor`（B）；组件不再手写 tertiary/contentCard 叠色。
- **文档**：`AppColor` 注释与 `project.md` 主题色约定补充 panelGlass 角色；不改 Feed `contentCard` 浅卡策略。
- 不新建 `**/test/**`。

## Capabilities

### New Capabilities

- `theme-panel-glass`：页内玻璃 chrome 原子目录、暗壳非白起笔、可选 accent 渐变、以及预测页迁入验收。

### Modified Capabilities

- `app-visual-tokens`：派生入口增加 panelGlass 成对字段（或等价别名）及暗壳非白起笔义务。

## Impact

- **主题**：`app_visual_tokens.dart`（可选字段）、`theme_preset.dart` `toTokens()`、`app_color.dart`。
- **UI**：`smart_prediction_screen.dart`（tip / `_CareAlertShell` / 事件卡装饰）。
- **文档**：`openspec/project.md` 主题色约定一行补充。
- **验证**：夜空下 tip/留意/预测卡不发白、正文可读；经典浅色观感可接受；事件卡仍可带事件色强调。
