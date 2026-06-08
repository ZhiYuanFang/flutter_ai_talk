## Context

- **现状**：UCG 在 `add-ucg-module` 中约定与喂养模块一致的玻璃拟态（`UcgShellGlassCard`、`UcgGlassBottomDock`、`UcgGlassInputDock`、`showGlassAdaptiveBottomSheet`）。广场双列 Feed、沉浸式顶栏、我的动态时间轴等已部分偏简约，但整体仍大量依赖 `BackdropFilter` + 渐变描边。
- **键盘桥接**：全 App 已在 `app.dart` 挂载 `KeyboardInputConfirmBarOverlay` 与 `keyboardInputBridgeController`（`keyboard-top-input-confirm-bar` 基线）。喂养、登录、历史编辑等页面已 `attach`；UCG 全部 `TextField` 未接入，且 `UcgScaffold` 默认 `resizeToAvoidBottomInset: true` 导致键盘顶起内容。
- **约束**：主题色仍走 `AppVisualTokens` / `ColorScheme.primary`；喂养模块玻璃体系不改动；`UcgEnterSquareTab` 不在本次范围。

## Goals / Non-Goals

**Goals:**

- 建立 UCG **简约风**视觉 primitive：`UcgSurfaceCard`（轻表面）、`UcgBottomDock`（扁平底栏）、`UcgInputDock`（扁平输入条）、轻量选中态（颜色+字重）。
- 迁移 UCG 内所有 `UcgShellGlassCard` / 玻璃 dock 调用点至新 primitive。
- 保留帖子详情页首图/封面 **氛围 blur**；广场 Feed 使用 **轻表面卡**。
- 新增 `ManagedKeyboardTextField`，UCG 五处输入全量接入键盘确认条；`UcgScaffold` 默认 `resizeToAvoidBottomInset: false`。
- UCG 评论 Sheet 改为 flat sheet + 键盘桥接（`respectKeyboardInset: false`）。
- OpenSpec delta 覆盖 `ucg-visual-system`、`ucg-shell-navigation` 等，supersede 先前玻璃 dock / Masonry 玻璃卡条款。

**Non-Goals:**

- 喂养页 `UcgEnterSquareTab` 视觉改造。
- 全局 `KeyboardInputConfirmBarOverlay` 皮肤改版（仍用现有 Material 确认条）。
- 后端 API、WS 协议变更。
- 详情页去掉背景 `BackdropFilter`。

## Decisions

### 1. 枢纽组件：`UcgSurfaceCard` 替换 `UcgShellGlassCard`

**Decision**：在 `ucg_visual_widgets.dart` 将 `UcgShellGlassCard` 实现改为轻表面（单色 `recordsCardColor` 或 `themePrimaryBlend(alpha: 0.06)` 填充、`surfaceRadius` 圆角、无 `BackdropFilter`、无 `panelShadow`、可选 1px `onShell 8%` 描边或无边框）。保留类名别名过渡期：`typedef UcgGlassCard = UcgSurfaceCard` 或直接重命名并批量替换 import。

**Alternatives**：每处调用点手写 `DecoratedBox` — 拒绝（重复、难维护）。

### 2. 底栏：`UcgBottomDock` 全宽扁平

**Decision**：删除 pill 容器（`ClipRRect`、`BackdropFilter`、`DecoratedBox` 渐变）。`Row` 五等分槽位：广场、宝藏、发布（`Icons.add_rounded` + label「发布」）、消息、我的。选中态仅 `primary` 色 + `fontWeight w600`；中间发布槽无选中态、`onConfirm` 打开发布 route。高度约 56–60，padding 仅 safe area bottom。

**Alternatives**：保留悬浮 pill 仅去 blur — 拒绝（不符合「嵌入 shell」产品决策）。

### 3. Feed 卡片：轻表面包裹

**Decision**：`UcgMasonryFeedCard` 外包 `UcgSurfaceCard`（padding 10、radius 12），双列布局与交互矩阵不变。

### 4. 详情页：氛围 blur 保留，Sheet 改 flat

**Decision**：`UcgPostDetailScreen` 背景 Stack 保留 `BackdropFilter` + `shellBg` scrim。评论输入改 `showModalBottomSheet` 或 thin wrapper（非 `showGlassAdaptiveBottomSheet`），`respectKeyboardInset: false`，Sheet 内 `ManagedKeyboardTextField` 接入 bridge。

### 5. `ManagedKeyboardTextField`

**Decision**：新增 `app/lib/ui/widgets/managed_keyboard_text_field.dart`，封装：

- 内部 `FocusNode` + `focusNode.addListener` → `attach` / `detach`
- `onChanged` → `keyboardInputBridgeController.updateDraft`
- 参数：`controller`、`hint`、`scene`、`onConfirm`、`obscureText`、`enabled`、`maxLines`、标准 `InputDecoration` 透传

UCG 聊天 dock、compose 正文、评论 Sheet、资料昵称/简介均使用该组件或等效模式。

**Alternatives**：每页复制喂养手写样板 — 拒绝（易漏、不符合「后续新功能一致」）。

### 6. `UcgScaffold` 默认不顶起

**Decision**：`UcgScaffold` 的 `Scaffold` 增加 `resizeToAvoidBottomInset: false`（可构造参数覆盖，默认 false）。

### 7. 互动 Chip 与发送按钮简约化

**Decision**：`UcgInteractionChip` 去掉 `StadiumBorder` 描边胶囊，改为 icon + label 轻量文字按钮；`UcgInputDock` 发送按钮去掉渐变圆，改为 flat `IconButton` 或 primary 色 icon。

### 8. 与 OpenSpec 关系

**Decision**：本变更 MODIFIED `add-ucg-module` 的 `ucg-visual-system` / `ucg-shell-navigation`；ADDED `managed-keyboard-textfield`；扩展 `keyboard-top-input-confirm-bar` UCG Scenario。`ucg-square-detail-notifications-redesign` 中 Masonry 玻璃卡任务若已实现，以本变更覆盖。

## Risks / Trade-offs

- **[Risk] 暗色 shell 下轻表面卡对比不足** → 使用 `recordsCardColor` token；实现后浅色/暗色主题手工验证。
- **[Risk] 多行 compose 正文在确认条仅单行省略** → 沿用基线行为；长文编辑依赖页面内 Field 滚动（键盘不顶起时 Field 可能被挡，用户主要靠确认条镜像）——与喂养模块一致。
- **[Risk] 类名重命名 (`UcgGlass*` → `Ucg*`) 影响面广** → 分阶段：先改实现保留旧名 deprecated typedef，tasks 末步清理。
- **[Risk] 评论 Sheet 去 `respectKeyboardInset` 后 UX 变化** → 依赖键盘确认条展示输入内容；与产品已定喂养一致路径。

## Migration Plan

1. 落地 `ManagedKeyboardTextField` + `UcgSurfaceCard` / `UcgBottomDock` primitive。
2. 改 `UcgScaffold`；迁移底栏与 Feed 卡（用户可见变化最大）。
3. 批量替换 `UcgShellGlassCard` 调用（消息、我的、compose、profile）。
4. 接入五处键盘 bridge；评论 Sheet 改 flat。
5. 简约化 `UcgInteractionChip`、输入 dock 发送钮。
6. 全模块 `flutter run` 手工路径：五栏切换、发帖、聊天、评论、资料编辑、浅/暗主题。

**Rollback**：Git revert 单变更；无数据迁移。

## Open Questions

- 无（探索阶段已锁定：轻表面 Feed、详情 blur 保留、enter tab 不纳入、底栏扁平、键盘桥接全量）。
