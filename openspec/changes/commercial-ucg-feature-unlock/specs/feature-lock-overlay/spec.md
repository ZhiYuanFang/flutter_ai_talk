## ADDED Requirements

### Requirement: FeatureLockOverlay SHALL use blur and center lock over real content

Wherever a commercial feature lock is shown (UCG full-screen gate or prediction event card), the client MUST render a shared `FeatureLockOverlay` (or equivalent shared widget) over the **real** underlying UI: Gaussian blur of the background content plus a **light translucent scrim** so underlying content remains faintly visible but unreadable, and a center lock affordance **without** crossed-chain decoration. The overlay MUST NOT use an opaque panel-glass fill that fully hides the blurred content. The overlay MUST NOT replace locked prediction events with virtual/skeleton-only placeholders. Prediction card lock copy MUST use「点击开通」. Colors MUST use semantic `AppColor` tokens (e.g. lock scrim / shell-derived tint); hard-coded near-white solid glass for dark shell MUST NOT be used.

商业锁定浮层（UCG 全屏或预测事件卡）**必须** 使用统一 `FeatureLockOverlay`：在真实内容上高斯模糊 + **浅透罩**（底图依稀可辨但看不清）+ **仅中心锁**（**不得** 绘制交叉锁链）；**不得** 用实心 panelGlass 盖死底图；**不得** 用虚拟骨架替换锁定预测事件；预测卡文案 **必须** 为「点击开通」；取色 **必须** 走语义原子。

#### Scenario: 预测锁定卡叠在真实事件上

- **WHEN** 某条真实预测行处于锁定态
- **THEN** 客户端 MUST 仍渲染该事件完整卡面内容
- **AND** MUST 在其上叠加 FeatureLockOverlay
- **AND** MUST 展示文案「点击开通」
- **AND** MUST NOT 仅用骨架卡替代该事件

#### Scenario: 浅透模糊可辨底图

- **WHEN** FeatureLockOverlay 叠在真实内容上
- **THEN** 罩层 MUST 为低透明度 tint（非不透明 panelGlass 渐变）
- **AND** 用户 MUST 能感知底图轮廓/色块但无法清晰阅读底图正文

#### Scenario: UCG 全屏锁复用同一视觉语言

- **WHEN** UCG 入口闸门展示全屏锁
- **THEN** 浮层 MUST 使用与预测锁同一套模糊+浅透+中心锁视觉组件族（可有天数/返回按钮扩展槽；MUST NOT 交叉锁链）

#### Scenario: 浮层无交叉锁链

- **WHEN** FeatureLockOverlay 展示于预测卡或 UCG 全屏闸门
- **THEN** 浮层 MUST 展示中心锁图标
- **AND** MUST NOT 绘制交叉锁链装饰
