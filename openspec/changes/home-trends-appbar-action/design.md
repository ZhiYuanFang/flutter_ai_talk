## Context

- `home_screen.dart`：`AppBar` 含标题「胖宝」、actions 为历史 WS + 设置；底部 `SizedBox(height: 220)` 内 `Stack` 含居中主输入、`Positioned(right:24, top:16)` 趋势按钮、右下角输入模式切换。

## Goals / Non-Goals

**Goals:**

- 趋势入口在 **AppBar 右侧**，图标 `Icons.insights`，`tooltip: 趋势`。
- actions 顺序（从左到右）：`cloud_*`（历史 WS）→ `insights`（趋势）→ `settings`（设置）。
- 底部输入区不再渲染趋势按钮，避免遮挡字幕/语音球。

**Non-Goals:**

- 不改趋势中心页面、路由表、历史/语音 WS 行为。
- 不改设置入口位置。

## Decisions

### 1. 控件形态

- AppBar 使用 **`IconButton`**（与历史、设置一致），不用底部的大 `FilledButton.tonalIcon`。
- `onPressed: () => context.push('/trends')`。

### 2. AppBar actions 示意

```
[ 胖宝                    [云] [趋势] [设置] ]
```

### 3. 底部 Stack

- 删除 `Positioned` 趋势块。
- 保留 `_buildPrimaryHomeInput` 居中、`_buildInputModeToggle` 仍在 `right:16, bottom:12`（若启用）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 与旧 Spec「主输入区右上方」字面不一致 | delta spec 更新为 AppBar 右侧 |
| actions 过多挤占顶栏 | 均为图标，可接受 |

## Migration Plan

- 纯 UI 调整，发版即生效。

## Open Questions

- 无。
