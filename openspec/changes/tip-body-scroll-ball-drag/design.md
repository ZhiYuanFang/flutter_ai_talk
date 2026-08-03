## Context

`tip-tap-body-to-companion` 已去掉关闭/对话、改为 done 点文案进陪伴，但展开卡仍挂 `onPan*`，且 `ClinicAnswerBody` `selectable: true` + `NeverScrollableScrollPhysics`，点按常失败。产品冻结：**正文可滚不可拖；仅缩进成球后拖图标。**

## Goals / Non-Goals

**Goals:**

- 展开：ScrollView 滚文案；无 pan 拖卡；done 点正文可靠进陪伴；顶标仅折叠。
- 球：沿用 EdgeDockShell 拖/贴边/拉出/点开。
- 修 tap 被 pan/选区抢走。

**Non-Goals:**

- 不恢复展开态过半吸入。
- 不改壳基线 peek 点按=engage。
- 不改陪伴页答案区滚动策略（除非抽公共参数）。

## Decisions

### 1. 手势分层

| 区域/态 | 允许 |
|---------|------|
| 展开正文 | 竖滑滚动；tap→陪伴（done） |
| 展开顶标 | tap→折叠浮空球 |
| 展开整体 | **无** pan / 无过半贴边 |
| 球（floating/peek/engaged） | 壳拖动、贴边、拉满业务、点开 |

### 2. 滚动与 tap

- tip：`SingleChildScrollView` 包正文，或 `ClinicAnswerBody(scrollable: true, selectable: false)`。
- 正文外包 `GestureDetector(onTap: …)` **不**挂 pan；滚动由 ScrollView 认竖滑。
- 横滑 PageView：展开 tip 仍可用现有 pointer 占用锁滑（Listener），避免滚文案时误切页——若竖滑与锁滑冲突，优先保证滚内容时 `onDockDraggingChanged(true)` 仅在 tip 指针按下时占用（已有 `_absorbPageScroll`）。

### 3. 删除展开拖动代码

- 移除 `_onPanStart/Update/End`、`_dragOffset` 驱动的展开位移与 `_edgePastHalf` 过半交壳（或保留函数但展开路径不调用）。
- 贴边仅：折叠后用户拖球吸附。

### 4. 否决

- 保留展开 pan + slop 分流 tap：否决——已证不可靠，且与「文案不可拖」冲突。

## Risks / Trade-offs

- [长文滚动 vs 点进陪伴] → 短位移走滚；抬起未滚可用 InkWell/GestureDetector；滚动中不导航。  
- [用户不知如何贴边] → 顶标折叠是唯一入口；可后续加弱提示（本变更不做）。  
- [与 edge-minimize「无滚动」冲突] → 以本 change 为准。

## Migration Plan

1. 改 `HomeTipPanel` 展开手势与滚动。  
2. 参数化 `ClinicAnswerBody`（若需要）。  
3. 手工：滚文案、点进陪伴、顶标折叠后拖球贴边。  

## Open Questions

- 无。
