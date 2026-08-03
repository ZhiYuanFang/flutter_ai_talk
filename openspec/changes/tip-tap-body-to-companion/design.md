## Context

`home-tip-center-card` 将进陪伴改为下方「对话」、并提供「关闭」dismiss。产品现冻结：**完全不要关闭按钮式 dismiss**；**仅 done 点文案进陪伴**。折叠/贴边最小化仍保留内容。

## Goals / Non-Goals

**Goals:**

- 删除「关闭」「对话」UI 与接线。
- 文案区（卡片正文）tap：仅 `done` → `homePagerRequestProvider.requestPage(companion)`（沿用注入）。
- streaming/thinking：文案 tap 不导航；仍可拖动与顶标折叠。
- 顶标 tap 仍折叠成球，不进陪伴、不 dismiss。

**Non-Goals:**

- 不新增其它 dismiss 入口（长按关闭等）。
- 不改 tip SSE、`shouldShow`、贴边壳基线。
- 不修 `EdgeDockShell` `_edge` LateInit（另修）。

## Decisions

### 1. 无显式 dismiss

- 用户收起：顶标折叠 / 拖到贴边；内容仍在 tipProvider。
- 替换：新 tip `presentationGeneration` 仍强制居中展开。
- 进陪伴后是否清主页 tip：沿用现有 companion bridge 消费/注入语义，本变更不新开 dismiss API。

### 2. 文案 tap 条件

- `displayState == done` 且既有可注入条件（如 `injectText` 非空，与原「对话」enabled 对齐）。
- streaming：忽略 tap（不 snackbar 也可）。

### 3. 手势分流

- 卡片正文：`GestureDetector` / Listener 统一 pan；抬起未过 slop → 若 done 则进陪伴。
- 顶标：独立 onTap 折叠，不冒泡进陪伴。
- 删除按钮 Row 后 Column 仅卡+标，拖动热区更干净。

### 4. 否决

- 顶标改 dismiss：否决（与折叠冲突）。
- streaming 也可进陪伴：否决（产品「仅 done」）。

## Risks / Trade-offs

- [无法丢掉 tip] → 产品接受；仅最小化/替换/进陪伴消费。  
- [拖动误触进陪伴] → slop 与现 pan 一致。  
- [与未归档 center-card / gesture 文档冲突] → 以本 change spec 为准。

## Migration Plan

1. 改 `HomeTipPanel` UI 与 tap。  
2. 手工：无按钮；done 点文案进陪伴；streaming 点无效；顶标仍折叠。  
回滚：恢复按钮 Row。

## Open Questions

- 无（完全不要关闭；仅 done 进陪伴 已冻结）。
