## Context

`UcgProfileShell` 用 `SliverPersistentHeader` + `Clip.hardEdge` 折叠资料卡与头像 morph。`maxExtent` 对主人写死 `248`、访客用手估块高；卡内加邀请行后被裁。`SliverPersistentHeader` 必须在 layout 前提供 `maxExtent`，不能直接靠 Column 自动撑开盒子。

## Goals / Non-Goals

**Goals:**

- `maxExtent` 最终值 = toolbar + flexibleTopPad + **实测资料卡高度**。
- 去掉主人 `248` / 访客块高常量作为最终真相。
- 测高完成前用 **占位 maxExtent**，避免过矮→正确高的闪屏/列表跳。
- 内容变更后重测；保留 pinned 折叠与 morph。

**Non-Goals:**

- 不把邀请行挪出 header（本变更用测高解决问题）。
- 不改 morph 视觉公式语义（仍用 shrinkOffset / range）。
- 不改邀请 / 关注 / 发帖 API。
- 不新建 `**/test/**`。

## Decisions

### D1：测高驱动 maxExtent（非魔法终值）

壳层持有 `measuredCardHeight`（可空）。

```
maxExtent = toolbar + flexibleTopPad + (measuredCardHeight ?? placeholderCardHeight)
```

`placeholderCardHeight`：偏 **保守偏高或接近历史下限** 的稳定占位（可沿用旧公式/旧 248 作首帧占位），**仅**用于测高完成前；测得后以实测为准。占位 **不得** 长期小于真实卡高（否则仍裁切闪一下）；宁可略高再收一点。

**备选**：公式加 invite 常量 — 否决（仍会再忘）。  
**备选**：邀请挪出 header — 另案；本变更按用户选定测高。

### D2：测高方式

在与可见卡同宽约束下测量资料卡内容（owner / viewer 对应 widget）：

- **采用**：壳层 `Offstage` + 定宽 `SizedBox`（`screenWidth - 32`）挂同构资料卡 + `GlobalKey`，post-frame 读 `RenderBox.size`；高度变化 ≥1px 再 `setState`。
- 探针外层 **必须** `Align(widthFactor: 1, heightFactor: 1)`（或等价 shrink-wrap），避免 `Column(MainAxisSize.max)` 在全屏约束下量到近屏高。
- 测高结果 **必须** sanity：卡高明显过大（如 > 0.55×屏高）则丢弃，保留占位/旧实测。
- **禁止**：在折叠头 `Stack`/`Positioned` 内使用 `OverflowBox(maxHeight: infinity)`（会触发 infinite layout / NaN）。

测高依赖：`profile`（bio 等）、`wxBound`、`showOwnerActions`、访客 actions、邀请异步态（`inviteMineProvider` loading→data 可能变高）。

### D3：占位防闪

```
冷启 / 重置：
  measured = null → maxExtent 用 placeholder（≥ 预期常见卡高）
首帧测完：
  measured = h → 若 |h - placeholder| 大，一次更新；morph range 同步变
内容变高（邀请出现）：
  重测 → 更新 measured（占位不再使用）
```

避免：先用过矮占位（如仅头像行）再跳到全高 —— 那正是闪屏来源。

### D4：delegate 重建

`expandedHeight` 变化时 `shouldRebuild` 已比较该字段；壳 `setState` 传入新 height 即可。滚动中途变高可能轻微跳变 —— 可接受；优先保证展开态不裁切。

### D5：删除或降级魔法常量

`_headerExpandedHeight` 中主人 `248`、访客块高 **不得** 再作为测高完成后的终值。占位阶段可暂时复用旧常量作 `placeholderCardHeight` 来源，并在注释标明「仅占位」。

## Risks / Trade-offs

- [首帧仍可能微跳] → 占位取偏高/贴近旧值；阈值合并 setState。  
- [滚动中变高] → 接受或仅在 shrinkOffset≈0 时应用；首版接受。  
- [测高失败] → 回退占位并 `AppDebugLog`（若已有合适 tag；勿裸 print）；不得静默用过矮值。  
- [Offstage 双份构建成本] → 可接受；换来布局稳定。  
- [可见树 OverflowBox(∞)] → **已否决**（infinite layout）。

## Migration Plan

- 纯客户端。回滚：恢复 `_headerExpandedHeight` 魔法数。

## Open Questions

- 无（测高 + 占位防闪已锁定）。
