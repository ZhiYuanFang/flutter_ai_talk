## Context

`HomeTipPanel` 现以 `Positioned(top:0)` 叠在历史列表上方，半透明背景、右上 ✕、`done` 整卡进陪伴；`shouldShow` 绑定 `displayState != idle`，streaming 空内容也可能占位。产品要求居中卡片、有思考即显、弹性入场、下方双按钮、历史可点、替换再弹。

触发仍由本机按钮 add HTTP 成功 → `tipProvider.startStreaming`（见 `sync-feed-add-remove-outbox` / `home-tip-on-feed-add`），本变更只改呈现与关闭/进陪伴入口。

## Goals / Non-Goals

**Goals:**

- 主页可视区居中展示 tip 卡片 + 下方「关闭」「对话」。
- 有 `thinking` 或 `answer` 非空才可见；弹性 scale 入场；不透明表面。
- streaming/thinking 可关闭；对话仅 done；无遮罩挡历史。
- 新 tip 替换旧内容并再播入场。

**Non-Goals:**

- 不改 tip SSE 协议、限流、feedback API。
- 不改陪伴注入规则本身（仅改首页入口控件）。
- 不做模态遮罩 / 背景变暗。
- 不新建 Debug tag（除非实现期确需诊断再开）。

## Decisions

### 1. 挂载：主页 Stack 居中，HitTest 穿透空白

- **决策**：将 `HomeTipPanel` 从历史区顶条改为覆盖主页内容区（或历史 Stack）的 `Align(alignment: center)` / `Positioned.fill` + 居中列；**仅卡片与按钮接收手势**，周围透明区域 `IgnorePointer` 或默认不占 hit（子级有界），保证历史可点。
- **备选**：全屏 `ModalBarrier` —— 已否决（产品：历史可点）。

### 2. `shouldShow` = 有可展示文本

- **决策**：`TipContent.shouldShow`（或面板等价判断）改为 `(thinking.trim().isNotEmpty || answer.trim().isNotEmpty) && displayState != idle`，且 `closing` 按动画需要短暂保留或改为直接 `completeDismiss`。
- **备选**：仅 `done` —— 已否决（要展示思考）。

### 3. 入场：Scale + elastic；用 generation 驱动再弹

- **决策**：`AnimationController` + `Curves.elasticOut`（或 `easeOutBack`）从约 0.6→1.0 scale；在「无可展示 → 有内容」或 `startStreaming` 重置时 bump `presentationGeneration`（int），`HomeTipPanel` listen 后重播动画。
- **关闭**：可缩回或直接清状态；优先简短 reverse scale 或立即 `completeDismiss`，去掉依赖高度折叠的 ✕ 路径。
- **备选**：仅 `AnimatedSize` —— 不够「弹性放大」。

### 4. 下方按钮，去掉整卡导航与 ✕

- **决策**：卡片下方一排：`关闭` → `dismiss`（streaming/done 均可）；`对话` → `homePagerRequestProvider.requestPage(companion)`，仅 `displayState == done` 且 `canInjectToCompanion`（或至少 done + 有文本）启用。卡片本体不再 `GestureDetector` 进陪伴。
- **理由**：入口明确；streaming 不注入半成品。

### 5. 背景不透明

- **决策**：`surfaceContainerHighest`（或 theme surface）**alpha = 1.0**；保留圆角与细边框可选。
- **备选**：毛玻璃 —— 超出范围。

### 6. dismiss 与 in-flight SSE

- **决策**：关闭时 UI/状态回 idle；后台 SSE **MAY** 继续跑完但结果丢弃（`startStreaming` 已有重置语义）；若实现简单可在 dismiss 时忽略后续事件（generation / cancel token）。不强制 abort HTTP（Flutter SSE 取消若已有则用）。
- **替换**：新 `startStreaming` 已重置 state → 自然换内容 + bump generation。

### 7. 与 companion-bridge 对齐

- **决策**：MODIFIED：整卡 tap 需求改为「对话」按钮；横滑进陪伴仍注入未消费 done tip。

## Risks / Trade-offs

- [居中挡视线但仍可点历史] → 接受；卡片勿过大（建议 maxWidth ~屏宽-48、maxHeight ~屏高 40%）。
- [elastic 在 `disableAnimations` 下刺眼] → 遵循 `MediaQuery.disableAnimationsOf`，跳过或瞬时完成。
- [thinking 中关闭后 SSE 晚到又弹出] → dismiss 后用 stream generation 忽略旧流事件。
- [与顶条 tip 并存的旧 Positioned] → 实现时删除顶条挂载，避免双实例。

## Migration Plan

- 纯客户端 UI；热更新即可。无数据迁移。
- 回滚：恢复 `HomeTipPanel` 顶条半透明 + ✕ + 整卡 tap。

## Open Questions

- 无（产品已冻结：thinking 可关、历史可点、替换再弹）。
