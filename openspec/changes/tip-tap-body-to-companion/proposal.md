## Why

居中 tip 下方「关闭 / 对话」占空间且与「贴边最小化保留内容」重叠；产品改为**无显式 dismiss**，进陪伴入口回到**点文案区**，且**仅 done** 可进，避免流式未完成误跳。

## What Changes

- **BREAKING**：删除 tip 展开态「关闭」「对话」按钮及对「关闭」dismiss 的依赖。
- 展开态**点文案区域**（非顶标）：`displayState == done` 时切至陪伴页并沿用既有 tip 注入；streaming/thinking **不得**因此进陪伴。
- tip 内容收起路径保留：**顶标折叠**、**四边贴边球**、新 tip 替换；**不**提供关闭按钮式 dismiss。
- 手势：文案区 tap / pan 用 slop 分流；顶标点仍原地折叠，不进陪伴。

## Capabilities

### New Capabilities

-（无）

### Modified Capabilities

- `home-tip-center-presentation`：去掉下方关闭/对话 MUST；居中不透明卡仍保留。
- `home-tip-companion-bridge`：进陪伴入口由「对话」改回文案区 tap（仅 done）；streaming 无效。
- `home-tip-gesture-chrome`：删除「关闭/对话不参与 pan」；补充文案 tap vs pan、顶标仍折叠。
- `home-tip-edge-dock`：去掉「关闭仍 dismiss」对按钮的依赖；最小化 ≠ dismiss 仍成立。

## Impact

- 代码：主要 `app/lib/ui/widgets/home_tip_panel.dart`；pager / tip 注入沿用现有路径。
- 依赖未归档 tip/edge 系列 change；以本 change 覆盖入口与 dismiss 产品句。
- 不改 tip SSE 触发、不改 Android 原生。
