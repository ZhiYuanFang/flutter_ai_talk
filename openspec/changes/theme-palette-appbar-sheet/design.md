## Context

主题 UI 在 `settings_screen` 的 `_ThemePresetSection` / `_ThemeSectionHeader`。主壳三页顶栏：喂养 `HomeImmersiveHeader`（趋势最右）、预测自建 Row（布局切换最右）、UCG `UcgImmersiveHeader.actions`。产品要求入口迁到主壳顶栏最右调色盘 + 公用 Sheet，设置不再放主题块。

## Goals / Non-Goals

**Goals:**

- 仅主壳三页（喂养 / 预测 / UCG）顶栏最右固定调色盘。
- 喂养：趋势保留，调色盘在其右侧。
- 单一 `showThemePaletteSheet`（或等价）供三页共用；内含经典/夜空/彩色、色盘默认展示、自动夜空。
- 改自定义色 → 自动选中「彩色」并持久化。
- 设置页移除主题区块。

**Non-Goals:**

- 不改主题派生公式（`lightTintedBundle` / 夜空调度窗口）。
- 不强制登录门闩；不覆盖趋势/二级页。
- 不新建测试文件。

## Decisions

### 1. 公用 Sheet + 入口按钮

```
ThemePaletteIconButton → showThemePaletteSheet(context)
  Sheet 内容：从设置抽出的预设 + 色盘 + 自动夜空
  persist / refreshScheduledTheme / homeWidget sync 与现设置相同
```

禁止在三页各写一份 Sheet 逻辑。

### 2. 色盘默认展示与彩色自动选中

- Sheet 打开时色盘区域**默认可见**（不再依赖「先点彩色再展开」）。
- 用户在色盘选色 / 拖动改色 → 选中态切到「彩色」，`preset=null` + 写入 seed。
- 点「经典」「夜空」仍切换基线；色盘可保留预览，选中 chip 以基线为准。

### 3. 自动夜空

- Sheet 内保留 Switch；开启时自定义选色控件禁用或不可用（对齐既有「开启时不得提供自定义选色」）。
- 不因开启而清除已持久化自定义 seed。

### 4. 顶栏接线

- 喂养：`HomeImmersiveHeader` 增加最右 palette；趋势在其左。
- 预测：布局按钮之右加 palette。
- UCG：各主壳可见 `UcgImmersiveHeader` 的 `actions` 末尾追加同一按钮（或 shell 统一注入）。

### 5. 设置

删除主题相关 Section；其它设置项不动。

## Risks / Trade-offs

- [UCG 多 Tab 顶栏] → 每个可见 header actions 末尾加同一按钮，或漏 Tab；验收时扫广场/消息等主壳 Tab。
- [Sheet 与调度同时改] → 沿用现有 `refreshScheduledTheme`，避免双写。

## Migration Plan

- 纯 UI 入口迁移；持久化键不变。回滚：恢复设置主题块、去掉顶栏按钮。

## Open Questions

- 无。
