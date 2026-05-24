## Why

主页输入模式切换目前是固定在底部输入区右下的三图标条，始终占位，与语音球、按钮网格争抢空间；用户希望改为**贴边半露的悬浮切换器**，可在整个首页范围内拖动并吸附四边，按需展开，减少常态遮挡。

`home-button-input-mode` 已落地语音 / 文字 / 按钮三种模式及 `HomeInputChannelStore` 持久化；本变更仅重构**切换器交互与布局**，不改变 add/chat 等业务逻辑。

## What Changes

- 移除底部输入区固定的 `_buildInputModeToggle` 三图标条（及文字模式为避让预留的右侧 padding）。
- 新增 **`HomeInputModeDock`**：浮于**整个首页 body**（历史列表 + 底部输入区之上），可拖动、四边吸附、**collapsed 半圆贴边**（仅当前模式图标一半露出）。
- **点击 collapsed** → 展开可选模式；**选中模式**或**点击外部** → 收起。
- **展开方向**与吸附边绑定：
  - 吸附 **上/下边** → 菜单 **水平** 排布（向屏幕内侧展开）；
  - 吸附 **左/右边** → 菜单 **竖向** 排布。
- 新增 **`HomeInputDockStore`**：持久化吸附边（`top|bottom|left|right`）与沿边偏移（归一化 0–1 或像素），冷启动恢复位置；与既有 `HomeInputChannelStore`（记模式）并存。
- 展开时使用全屏透明 **`ModalBarrier`**（或等价）捕获外部点击以收起；展开态不得阻断当前输入模式的核心手势（语音按住、按钮横向滚动等）——通过层级与 hit-test 策略在 design 中细化。
- **Web**：若 `_canSwitchInputMode` 为 false 则仍不展示；可拖动时仅保留 **左/右** 吸附（或禁用拖动，仅贴边点击展开），与 `WEB_HOME_INPUT` 策略一致。

## Capabilities

### New Capabilities

- `home-input-mode-dock`：贴边半露悬浮切换器、四边拖动吸附、按边展开方向、外部点击收起、位置持久化及与三种输入模式的集成。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线；对 `home-button-input-mode` 所描述的「底部并列三选一」UI 决策作**交互层替换**，业务需求（三种模式、add/chat 前置条件）不变。）

## Impact

- `app/lib/ui/home_screen.dart`：移除固定 toggle，接入 Dock overlay。
- 新组件 `app/lib/ui/home_input_mode_dock.dart`（及可选 `app/lib/config/home_input_dock_store.dart`）。
- `app/lib/config/home_input_channel_store.dart`：继续负责模式记忆，不合并 dock 位置（职责分离）。
- 无 API / 后端变更。

**Out of scope**：新增第四种输入模式；修改事件 add/chat 契约；非首页路由的输入切换。
