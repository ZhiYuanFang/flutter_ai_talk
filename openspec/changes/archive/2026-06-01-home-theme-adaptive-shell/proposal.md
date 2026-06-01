## Why

主页当前为浅色 Material3 布局，自定义背景色直接作为 `scaffoldBackgroundColor`，缺少参考 baby-tracker 风格的深色外壳、卡片容器、药丸摘要与底部网格 elevation 等层次；且视觉无法随用户主题色自适应（仅固定浅色或纯黑 `#000000` 预设）。需要在**不改动历史 WebSocket、事件目录与输入模式数据流**的前提下，引入主题自适应的视觉令牌与可选「夜空」预设，提升主页观感与个性化。

## What Changes

- 新增 **`AppVisualTokens` `ThemeExtension`**：定义 shell（外壳）、surface（卡片/面板）、pill（今日摘要 chip）、elevation/shadow/glow 等语义令牌；浅色与深色分支均可读取。
- **`buildAppTheme` 扩展**：保留经典浅色为默认；当用户种子色亮度低于阈值或选用「夜空」预设时，走**深色 shell 分支**，自用户种子色 HSL 推导 shell/surface（非写死 `#1A1C24`）；浅色模式仍用性别 primary 作 accent。
- **设置页主题区增强**：在「自定义背景颜色」旁增加**预设色块**（含新 **「夜空」** `shell #1A1C24`）；纯黑 `#000000` 预设**合并进「夜空」**（选夜空即等价于深色 shell 参考色，不再单独展示纯黑块）。
- **主页 Phase 1 视觉升级**（数据流不变）：
  - 今日摘要：药丸形 chip、容器内边距与阴影/描边随 tokens
  - 历史按日卡片：圆角容器、shell 上 surface 分层
  - 时间轴 tile：行高/字号/图标槽位与 tokens 对齐
  - 按钮模式网格：底部 elevated panel、cell 阴影与 EventLogo 槽位增强（仍用现有 EventLogo，3D 资产 Phase 2）
- **明确 Out of scope（Phase 2）**：趋势页/登录页深色适配、独立 3D 图标资源、替换语音/文字 dock 交互。

## Capabilities

### New Capabilities

- `app-visual-tokens`：`ThemeExtension` 令牌定义、HSL 自种子色推导深色 shell、浅色/深色双分支挂载于 `ThemeData`。
- `theme-settings-presets`：设置页主题预设 UI、「夜空」预设持久化与清除/恢复默认行为。
- `home-shell-visual-style`：主页今日 pill、日卡片、时间轴 tile、按钮网格与输入 dock 容器的视觉规范（不改 WS/目录/输入逻辑）。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线；主题与主页视觉在本变更新增规格中完整描述。）

## Impact

- `app/lib/theme/app_theme_scope.dart`：`buildAppTheme`、令牌注册、深色分支与 HSL 推导。
- 新增 `app/lib/theme/app_visual_tokens.dart`（或同级）及可选 `theme_preset.dart`。
- `app/lib/theme/custom_background_persist.dart`：可选扩展 preset id 持久化（与现有 `custom_bg_color` 兼容）。
- `app/lib/app.dart`：主题构建处传入 tokens。
- `app/lib/ui/settings_screen.dart`：`MaterialColorPicker` 预设扩展、「夜空」入口。
- 主页组件：`home_screen.dart`、`home_today_summary_panel.dart`、`home_history_scroll.dart`、`home_history_date_header.dart`、`home_history_timeline_tile.dart`、`home_button_event_grid.dart`、`home_input_mode_dock.dart` 等读取 tokens 替代硬编码颜色/圆角/阴影。

**产品默认决策（未单独确认项）**：经典浅色仍为默认；「夜空」为可选预设；性别 primary 在浅色模式作 accent，深色 shell 以用户种子 + 事件色作 chip 强调；趋势/登录 Phase 2。
