## Context

C′a 在助手玻璃上设 `clipBehavior: Clip.none`，与 `BackdropFilter` 冲突，整表气泡不可见。助手系统选区仍无法稳定提交，`contextMenuBuilder` 主路径不可用。用户气泡 `SelectableText` 仍可用。

## Goals / Non-Goals

**Goals:**

1. 恢复树洞消息气泡正常展示。  
2. 助手完成态：长按后在内容上方出现「复制」，可写入剪贴板。  
3. tip 注入助手气泡同路径。

**Non-Goals:**

- 继续用 `Clip.none` 救手柄。  
- 依赖系统选区手柄 / C′a `contextMenuBuilder` 作为主路径。  
- 用户气泡改 Overlay（已有系统选区）。  
- 首页 tip 可选。

## Decisions

### 1. 立刻修复：去掉 `Clip.none`

- 助手 `UcgComposeLightGlassPanel` **不再**传 `clipBehavior: Clip.none`（恢复默认抗锯齿裁剪）。
- `BackdropFilter` 必须保持被 `ClipRRect` 有效裁剪。

### 2. 拆除 C′a 主路径

- 去掉助手气泡外层 `SelectionArea` + `contextMenuBuilder`（避免无效选区壳与二次风险）。
- `ClinicAnswerBody` 恢复默认或显式 `selectable: false` 均可；展示优先，不靠 Markdown 内层选区完成复制。

### 3. 方案 C′b：长按 → 上方「复制」Overlay

```
长按助手气泡
    → 记录 global 位置 + 待复制文本
    → Overlay 在位置上方显示 [复制]
点击「复制」
    → Clipboard + toast「已复制」+ 关闭 Overlay
点击空白 / 滚动 / 再长按其它
    → 关闭 Overlay
```

**复制内容优先级：**

1. 若实现期能在长按拖动过程中可靠截获非空选区片段 → 用片段。  
2. 否则（默认预期）→ 复制该助手气泡**完整正文**（`item.answer` 原文）。

**定位：** `OverlayEntry` + 根据 `LongPressStartDetails.globalPosition` 偏移到点上方（约 48–56px）；注意避让屏幕顶边。

**手势：** `GestureDetector.onLongPressStart`（或 `Listener`）包住玻璃气泡；勿与列表滚动严重冲突（长按阈值走系统默认）。

### 4. 与玻璃组件 API

- `clipBehavior` 参数可保留（默认 `antiAlias`），助手路径不传 `Clip.none` 即可；不必强制删除该参数。

## Risks / Trade-offs

- [只能整段复制] → 产品可接受；优于完全不能复制。  
- [长按与列表滚动] → 使用长按而非短按；验证仍可竖滑。  
- [Overlay 残留] → 路由离开 / dispose 必 remove。  
- [Markdown 源码含标记] → 复制 `answer` 原文；若需纯文本可后续 strip，本 change 不强制。

## Migration Plan

1. 去掉 `Clip.none`，去掉助手 `SelectionArea`/`contextMenuBuilder`。  
2. 接长按 Overlay「复制」。  
3. 真机：气泡恢复；长按出按钮；复制成功。  
4. 回归用户选区、首页 tip。

可整 diff 回滚。

## Open Questions

- （无阻塞）是否同时复制「非医疗建议」脚注 — 默认否。
