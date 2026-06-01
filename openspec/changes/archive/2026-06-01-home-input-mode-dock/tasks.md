## 1. 持久化与模型

- [x] 1.1 新增 `HomeInputDockStore`（`edge` + `along` 0–1）；非法值回退默认 `right` / `0.75`
- [x] 1.2 定义 `DockEdge { top, bottom, left, right }` 及吸附 / 沿边坐标计算工具（SafeArea clamp）

## 2. Dock 组件

- [x] 2.1 新建 `HomeInputModeDock`：collapsed 半圆（当前模式图标）、直径与贴边裁切
- [x] 2.2 拖动手势 + `onPanEnd` 四边最近吸附；拖动结束写入 `HomeInputDockStore`
- [x] 2.3 点击 collapsed → `expanded`；展开菜单：上/下水平、左/右竖向，向屏内展开
- [x] 2.4 菜单项接 `_selectInputChannel`；选中后 collapse；当前项高亮；按钮项受 `_showButtonsInputMode` 控制
- [x] 2.5 展开态 dismiss：`ModalBarrier` 仅覆盖历史列表区（不罩底部 input panel）；点外部 collapse

## 3. HomeScreen 集成

- [x] 3.1 `body` 外层 `Stack` 挂载 Dock；启动时读取 dock 位置与 `HomeInputChannelStore` 模式
- [x] 3.2 移除 `_buildInputModeToggle` 及 bottom `Positioned` toggle
- [x] 3.3 去掉文字模式为 toggle 预留的右侧 56px padding；语音电平条 `right` offset 同步
- [x] 3.4 Web：`_canSwitchInputMode == false` 不展示；可切换时 dock 行为一致（Web `restrictToHorizontalEdges: true` 仅左右吸附）

## 4. 验证

- [x] 4.1 四边吸附 + 半圆贴边；切换模式后 collapsed 图标更新
- [x] 4.2 展开方向：底/顶水平、左/右竖向；选模式与点历史区外部均收起
- [x] 4.3 杀进程重进：dock 位置与输入模式均恢复
- [x] 4.4 展开态：语音球按住、按钮网格横滑仍可用；历史区点击可收起
