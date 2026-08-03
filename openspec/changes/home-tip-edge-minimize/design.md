## Context

`home-tip-center-card` 已将 tip 改为居中不透明卡 + 下方关闭/对话 + `presentationGeneration` 弹性入场。产品继续要求：顶标胖宝平拍圆、按钮实色、无卡内滚动、四边拖动最小化（类 `HomeInputModeDock`），且 docked 遇新 tip 强制居中再弹。

## Goals / Non-Goals

**Goals:**

- expanded ↔ docked 状态机；四边半圆贴边；过半宽/高触发吸入。
- docked 保留 tip 数据；关闭仍 dismiss；新 tip 强制 expanded 居中 + 弹性。
- 顶标/docked 圆共用 `kStartupIconAsset`；按钮不透明底；去掉 ScrollView。

**Non-Goals:**

- 不改 tip SSE / 服务端限长实现（仅约定客户端不滚动）。
- 不持久化 tip 贴边位置跨冷启动（MAY 会话内记忆；默认不写 Store，除非实现极便宜）。
- 不改造输入 dock 的吸附算法本体（仅 tip 侧避让）。
- 不做 tip 自由悬浮长期停在非贴边位置（松手未达阈值则回弹居中或回拖前 expanded 位——见决策）。

## Decisions

### 1. UI 形态状态放面板，内容仍在 tipProvider

- **决策**：`expanded | docked`（及 edge/along、drag offset）由 `HomeTipPanel`（或薄 `TipChromeController`）持有；`TipContent` 仍管 streaming/done/文本/generation。listen `presentationGeneration`：若 docked → 强制 `expanded`、清 drag、居中、重播入场。
- **备选**：把 docked 写入 TipContent —— 增加 provider 噪音，拒绝。

### 2. 过半贴边阈值

- **决策**：以 tip **布局包围盒**相对 home tip 可拖 bounds：若中心到某边距离 ≤ 该方向半尺寸（宽/2 或 高/2），或卡片越过该边超过一半面积的等价条件，则认定该边为吸附边；松手后播 scale morph → 半圆贴边（ClipRect 手法对齐 dock）。
- **未达阈值松手**：回弹到**屏幕居中** expanded（简单一致）。

### 3. 四边 + 与输入 dock 避让

- **决策**：四边均可 dock。吸附 `along` 时若与已知 dock 圆心距离 < 直径，则沿边偏移至少一个 tip 圆直径（实现可读当前 dock 位置若可注入，否则用经验偏移避开底右常见位）。
- **备选**：改 dock 让位 —— 范围过大。

### 4. 图标与布局 polish

- **决策**：顶标 `Image.asset(kStartupIconAsset)` 圆形裁剪，叠在卡片顶缘居中（可略重叠顶边）。卡内 `ClinicAnswerBody` 无 `SingleChildScrollView`。关闭/对话用实色 `FilledButton`/`FilledButton.tonal`（或等价 `backgroundColor` 不透明），禁用态仍可见底色降透明。

### 5. 手势

- **决策**：无滚动后，整卡（含正文）可拖；按钮 `onPressed` 优先（Listener/手势竞技场）。docked 圆：点击 → expanded 居中；拖出过阈值亦可展开。

### 6. 新 tip 强制展开

- **决策**：`presentationGeneration` 变化且面板 mounted：`uiMode=expanded`，位置重置居中，`_enterController.forward(from:0)`（disableAnimations 则跳过）。

## Risks / Trade-offs

- [与输入球重叠] → along 偏移；仍可能短时重叠。
- [服务端未限长导致溢出] → clip + 不滚动；不在本变更修服务端。
- [拖动与 PageView 横滑冲突] → tip 拖动中 `onDraggingChanged` 可锁 PageView（若首页已有 dock 同类回调则复用）。
- [elasticOut 与 morph 叠加晃] → 入场与吸入分控制器，不同时播。

## Migration Plan

- 纯 UI；热重载验证。回滚保留 center-card 行为即可。

## Open Questions

- 无（docked 新 tip → 强制居中再弹已冻结）。
