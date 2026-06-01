## Context

- 编辑入口：`showHomeHistoryEditSheet` → `showAppAdaptiveBottomSheet` + `_HomeHistoryEditSheetBody`。
- 现 UI：`EventNameHeader` 横排、`HomeHistoryTimeField`（Material surface 条 + schedule 图标）、日期只读行、备注 `OutlineInputBorder`、保存/删除纵向 `FilledButton`/`OutlinedButton`。
- 参考稿：深色玻璃卡片、居中 Logo/标题、时间条 + 铅笔、底栏取消/保存左右分布、右上关闭。
- 主题：`AppVisualTokens`、`resolveEventColor`、shell 明暗模式已存在。

## Goals / Non-Goals

**Goals:**

- 编辑 Sheet **仅视觉与布局**对齐参考稿；保留全部业务规则（见 `home-history-edit-sheet`）。
- 玻璃卡片：`BackdropFilter` blur（建议 sigma 16–24）+ 半透明深色/主题色渐变叠层 + 1px 高亮描边（white 10–20% alpha）。
- 圆角：建议 **20–24**；内边距 horizontal **20–24**。
- 关闭：`IconButton(Icons.close)` 右上，等同 dismiss（走现有 `PopScope` 脏检查）。
- 标题区：Logo **居中**（约 40–48px），其下事件名 **titleLarge/w600**、前景 onShell 或 white。
- 时间条：标签 `labelMedium` 在上；容器 minHeight ~52，大号时分 `titleLarge` tabular，右侧 `Icons.edit_outlined` 或 custom pencil。
- 底栏：`Row` — `TextButton('取消')` 左，`FilledButton` pill（全圆角 999）「保存」右；删除改为 `TextButton` 或 tertiary，置于底栏上方或更多菜单区。
- 计时 **停止**：保留，样式为 glass 内次级按钮或描边 pill。
- **pending** 只读：整体 opacity 降低，禁用交互，保留「同步中…」提示。

**Non-Goals:**

- 改时间滚轮子 Sheet 为玻璃风（可后续单独变更；本变更至少统一 `HomeHistoryTimeField` 触发条）。
- 改事件 catalog / number 添加 Sheet 全局样式。
- 引入新第三方 UI 库。

## Decisions

### 1. Shell 结构

```text
showModalBottomSheet(backgroundColor: transparent)
  └ SafeArea
       └ Padding(horizontal)
            └ HistoryEditGlassPanel (BackdropFilter + DecoratedBox)
                 ├ Stack: close button top-right
                 └ Column: logo, title, fields, actions
```

编辑 Sheet **不**改 `AppAdaptiveBottomSheet` 默认行为；在 `showHomeHistoryEditSheet` 传入 `backgroundColor: Colors.transparent`、`showDragHandle: false`，body 自包 glass panel。

### 2. 组件拆分

- `HistoryEditGlassPanel`：通用玻璃容器（child、padding）。
- `HistoryEditGlassTimeField`：包装现有 `HomeHistoryTimeField` 逻辑或抽 shared picker callback + 新 decoration。
- `_HomeHistoryEditSheetBody` 改用上述组件重组 layout。

### 3. 主题适配

- 浅色 shell：玻璃底用 `onShell` 反色深底 + 白字；或 `ColorScheme.surface` 80% + blur。
- 深色 shell：更接近参考稿；渐变可 subtle 事件色 tint（`resolveEventColor` 5–8% alpha）。
- 保存按钮：`ColorScheme.primary` 实心 pill；取消：`onShell` 90% 文本按钮。

### 4. 日期行

- 参考稿无独立日期行；**隐藏**原「日期：yyyy-MM-dd」行，日历日仍由 `anchorDate` 锚定（行为不变）。

### 5. 删除与保存布局

- 主底栏仅 **取消 | 保存**（与参考一致）。
- **删除**：底栏上方居中 `TextButton`（destructive color）或左下小字链接，避免三按钮挤占底栏。

## Risks / Trade-offs

- **[Risk] BackdropFilter 性能** → 限制 blur 区域为 Sheet 卡片尺寸；RepaintBoundary。
- **[Risk] 浅色模式对比不足** → 设计 token 双主题 QA。
- **[Trade-off] 与参考 1:1** → 用量滚轮/备注仍占位，略长于参考高度，可滚动。

## Migration Plan

- 纯 UI；手工验证 eventNumber 0/1/>1、pending、停止、删除、深浅色。

## Open Questions

- （默认）不新增「更多」菜单；删除保留为次级 TextButton。
