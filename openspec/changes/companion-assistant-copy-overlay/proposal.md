## Why

`companion-assistant-selection-copy`（C′a）在助手玻璃上使用 `Clip.none` 后，`BackdropFilter` 失去裁剪，导致树洞消息列表布局/绘制异常，**所有气泡不可见**。同时助手选区仍难稳定提交，系统 `contextMenuBuilder` 工具条不可靠。需要先恢复展示，再以不依赖手柄的选区上方「复制」（C′b）满足复制需求。

## What Changes

- **修复回归**：助手气泡去掉 `clipBehavior: Clip.none`，恢复玻璃默认裁剪，使消息列表重新正常展示。
- **弱化/移除对 C′a 的依赖**：不再依赖松手后系统选区手柄 + `contextMenuBuilder` 作为助手复制主路径（可保留无害的外层结构，或以更稳的手势路径替代）。
- **方案 C′b**：用户在助手答复上长按产生选区意图时，在选区（或长按位置）上方展示「复制」按钮；点击后将**可获得的选中片段**（若选区文本在松手前已捕获）或**回退为整段助手正文**写入剪贴板，并轻量 toast「已复制」。
- 用户气泡保持现有 `SelectableText`；首页 tip 仍不可选。
- 不改常驻复制图标为默认入口（入口仍是长按选区场景下的上方按钮）。

## Capabilities

### New Capabilities

- `companion-assistant-copy-overlay`：树洞助手气泡展示修复与长按选区上方「复制」Overlay。

### Modified Capabilities

- （无强制修改已合并基线；与进行中的 `companion-select-copy` / `companion-assistant-selection-copy` 互补，本变更以恢复展示 + C′b 为准。）

## Impact

- 代码：`pangbao_ai_screen.dart`（助手气泡）、必要时 `ucg_compose_light_glass_panel.dart`（仅当需收回无用的 clip API 时，非必须）。
- 依赖：`Overlay` / `CompositedTransformFollower` 或等价定位、`Clipboard`、`showAppToast`。
- 不改原生、不改后端、不新增 Debug tag。
