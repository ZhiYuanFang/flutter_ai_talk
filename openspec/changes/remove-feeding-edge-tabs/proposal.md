## Why

喂养页左右「进入陪伴 / 进入广场」贴边拉条与 tip 四边最小化、输入模式球抢边，且发现入口重复。产品改为**去掉拉条**，进入侧页仍靠 **PageView 左右滑**（及 tip「对话」、深链等既有路径）。

## What Changes

- **BREAKING**：喂养页 **不得** 再展示左缘「进入陪伴」、右缘「进入广场」可展开拉条（`UcgEnterCompanionTab` / `UcgEnterSquareTab`）。
- **保留**：三页 PageView；从喂养页 **左右横滑** 进入陪伴（page 0）与 UCG（page 2）；懒挂载、回喂养、tip 注入等壳行为不变。
- 删除或停止挂载拉条组件；拉条上的广场未读点随拉条消失（UCG 壳内消息 Tab 未读 **保留**）。
- tip「对话」、`homePagerRequestProvider`、深链进陪伴 **保留**。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `ucg-home-entry`：移除喂养页左右拉条及相关未读点绑定拉条的需求；明确横滑仍为进入侧页主手势。
- `smart-companion-ui`：进入陪伴入口描述去掉「拉条」。
- `home-tip-companion-bridge`：横滑进陪伴带 tip 的表述去掉「左缘拉条」。

## Impact

- 代码：`ucg_home_shell.dart` 去掉拉条挂载；可删 `ucg_enter_companion_tab.dart` / `ucg_enter_square_tab.dart`（若无其它引用）。
- 行为：喂养页更干净；用户需滑页进侧栏；广场未读不再出现在喂养右缘。
- 无 Android 原生改动。
