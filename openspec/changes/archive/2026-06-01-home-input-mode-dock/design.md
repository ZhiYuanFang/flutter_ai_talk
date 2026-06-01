## Context

- **现状**：`home_screen.dart` 在底部输入区 `Stack` 内 `Positioned(right: 16, bottom: 8)` 固定展示三图标 `_buildInputModeToggle`；文字模式 `padding` 右侧预留 56px 避让。
- **已有**：`_HomeInputChannel { voice, text, buttons }`、`HomeInputChannelStore` 持久化模式；`home-button-input-mode` 已实现按钮网格与 add 流程。
- **约束**：语音模式全 panel `Listener` 按住说话；按钮模式整表横向滚动；切换器不得长期遮挡主输入区中心。

## Goals / Non-Goals

**Goals:**

- 整个首页 body 内可拖动悬浮切换器；松手吸附 **上 / 下 / 左 / 右** 四边之一。
- **Collapsed**：完全贴边 **半圆**（D 形），仅 **当前模式** 图标可见（一半在屏内、一半在屏外或裁切为半圆）。
- **点击 collapsed** → 展开全部可用模式；**选中**或**点外部** → 收起。
- 展开布局：**上/下边** → **水平**菜单；**左/右边** → **竖向**菜单；菜单向屏幕 **内侧** 展开。
- **记住**吸附边与沿边位置，下次进入首页恢复（与 `HomeInputChannelStore` 独立）。
- 继续调用既有 `_selectInputChannel` / 模式可用性规则（Web、无按钮平台）。

**Non-Goals:**

- 修改 chat / event add API 或三种输入业务逻辑。
- 非 `HomeScreen` 路由的切换器。
- 第四种输入模式。

## Decisions

1. **层级与挂载点**  
   在 `HomeScreen` `Scaffold` `body` 最外层用 `Stack`：`Column(历史 + 输入区)` 为底，`HomeInputModeDock` 与展开态 `ModalBarrier` 置顶。拖动范围 clamp 在 **SafeArea 内矩形**（含历史列表与输入 panel），不覆盖 AppBar。

2. **Collapsed 半圆视觉**  
   - 圆形 hit target 直径 `d`（建议 48 logical px）。  
   - 圆心落在屏幕边缘线上，使 **恰好一半圆** 在屏内、一半在屏外（或 `ClipRect` + `Align` 裁切为半圆）。  
   - 图标为当前 `_inputChannel` 对应 `IconData`（🎤 / ⌨ / ⊞）。  
   - 贴边侧无阴影溢出到屏外（可选 `clipBehavior`）。

3. **拖动与吸附**  
   - `onPanUpdate` 更新自由坐标；`onPanEnd` 计算到四边距离，吸附 **最近边**。  
   - 沿边坐标 `along`：从左/上缘起的归一化位置 `0.0–1.0`，clamp 避免与圆角 / Home Indicator 重叠（留 `margin = d/2 + safeInset`）。  
   - 默认首次：`edge=right`，`along≈0.75`（接近原右下习惯）。

4. **展开方向与菜单布局**  
   | 吸附边 | 菜单主轴 | 展开方向 |
   |--------|----------|----------|
   | top | 水平 Row | 向下（进屏内） |
   | bottom | 水平 Row | 向上 |
   | left | 竖向 Column | 向右 |
   | right | 竖向 Column | 向左 |

   菜单项顺序固定：语音 → 文字 → 按钮（按钮项受 `_showButtonsInputMode` 控制隐藏）。当前选中项高亮。

5. **收起与外部点击**  
   - `expanded=true` 时插入全屏 `ModalBarrier`（半透明可选，建议低 alpha 或透明仅捕获点击）。  
   - 点击 barrier → `expanded=false`。  
   - 选中某模式 → `_selectInputChannel` + `expanded=false`。  
   - 展开态下 **collapsed 半圆仍可点**（切换为收起，若未选新模式）。

6. **手势冲突**  
   - Collapsed 仅半圆区域响应点击/拖动，不拦截历史列表（半圆面积小）。  
   - Expanded：barrier 在下层，菜单与 dock 在上层；**语音 orb 区域**（底部 panel 中央）在 barrier 之下仍可接收按住说话——实现上 barrier 使用 `IgnorePointer` 挖洞 **成本高**；**替代**：barrier 仅覆盖 **历史列表区域**，底部输入 panel 不罩 barrier，用户点输入区空白收起（或点历史区收起）。  
   - **首版决策**：barrier 全屏，但底部输入 panel 使用 `Listener` 优先级：若 expanded 且点击 panel 非菜单 → 收起；语音 orb 在 expanded 时 **仍可用**（barrier 不覆盖 input panel 高度区域）。即 barrier = `Positioned(top: 0, left: 0, right: 0, bottom: inputPanelHeight)`。

7. **持久化 `HomeInputDockStore`**  
   ```text
   edge: "top"|"bottom"|"left"|"right"
   along: double 0..1
   ```  
   SharedPreferences 键 `home_input_dock_v1`；拖动结束写入；非法值回退默认。

8. **移除旧 UI**  
   删除 `_buildInputModeToggle` 及文字模式 `_canSwitchInputMode ? 56 : 24` 右 padding；语音电平条 `right` offset 同步去掉 toggle 避让。

9. **Web**  
   - `_canSwitchInputMode == false`：不展示 dock。  
   - 可切换 voice/text 时：展示 dock，**禁用拖动**或仅允许 **左/右** 吸附（产品取 **仅左右 + 可拖动**，上下吸附在 Web 禁用），collapsed/expand 行为与移动端一致。

## Risks / Trade-offs

- **[Risk] 半圆 hit 区域过小难拖** → 扩大透明 drag slop（如 8px）或 collapsed 态拖动时临时显示完整圆预览。  
- **[Risk] 展开菜单挡历史行** → 菜单沿边展开、项数 ≤3，占用有限；必要时 flip 向内侧。  
- **[Risk] 与语音按住冲突** → barrier 不覆盖 input panel（Decision 6）。  
- **[Trade-off] 四边吸附 vs 仅左右** → 用户明确要求四边；Web 可降级。

## Migration Plan

- 发版后首次启动：无 dock prefs 时用默认右下；已有 `HomeInputChannelStore` 不受影响。  
- 无服务端变更；回滚即恢复固定 toggle 组件。

## Open Questions

- （已决）展开方向：上/下 → 水平，左/右 → 竖向。  
- （已决）半圆贴边，当前模式图标。  
- （已决）记住边 + 沿边位置。  
- （待实现验证）expanded 时 barrier 是否需轻微 dim（首版可透明）。
