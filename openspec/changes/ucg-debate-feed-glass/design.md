## Context

- 广场 Feed 当前：`UcgDebateFeedCard` → `UcgSurfaceCard`（纯色）；`UcgDebateVsBar` 含 `BackdropFilter` 与饱和蓝/粉，与 compose 页 `UcgComposeLightGlassPanel`（真玻璃）风格分裂。
- `ucg-debate-pivot` spec 曾要求广场卡 **NO BackdropFilter / NO gradient glass**；本变更将其演进为**允许渐变假玻璃、仍禁止 blur**。
- 用户已冻结：折中假玻璃、软糖马卡龙、emoji 中心、假玻璃降级（Web/截图）、详情/分享同步。

## Goals / Non-Goals

**Goals:**

- 推荐/关注列表辩论卡视觉统一为假玻璃，宝妈向「可爱」投票组件。
- 单一 `UcgDebateVsBar` 覆盖广场、详情、个人时间线（只读）、分享离屏布局。
- 列表滚动性能不劣化（无 per-item blur）。
- 分享 PNG 与 App 内卡片一致，利于微信裂变识别度。

**Non-Goals:**

- 不将 compose / 弹层 `UcgComposeLightGlassPanel` 改为假玻璃（弹层仍可真 blur）。
- 不改投票 API、计数、通知、小程序工程（色值对齐可后续做）。
- 不新增 Debug tag（除非实现阶段发现必要且三联改）。

## Decisions

### 1. 假玻璃 panel 独立于 compose 真玻璃

- **决策**：新增 `UcgFeedFakeGlassPanel`（或 `UcgFeedFakeGlassCard`），复制 `UcgComposeLightGlassPanel` 的渐变+白边+阴影结构，**删除** `BackdropFilter`。
- **理由**：Feed 长列表 blur 成本高；compose 单次展示可保留真玻璃。
- **备选**：复用 `UcgSurfaceCard` + `showBorder` — 拒绝，达不到「拟态」与 pivot 后内容形态匹配。

### 2. 共享 token 常量

- **决策**：在 panel 文件或 `ucg_debate_visual_tokens.dart` 集中定义：
  - `feedCardRadius = 16`
  - `vsBarRadius = 20`, `vsBarHeight = 54`
  - `macaronLeft = #B8DFF5 → #A8D4F0`, `macaronRight = #FFD4DC → #FFB5C5`
  - `centerEmoji = '✨'`（常量，后续可换 asset）
- **理由**：Feed / VS / Share 三色一致，避免 magic number 分叉。

### 3. VS 条去掉 blur，改软糖马卡龙

- **决策**：`UcgDebateVsBar` 外槽与色带均用线性渐变 + 白边；选中侧加粗白边与轻阴影；百分比可置于小圆角 sticker（白底 90% + 彩色字）增强「贴图感」。
- **理由**：与假玻璃卡协调；可读性优于白字压饱和色。
- **备选**：保留 blur 仅 VS 条 — 拒绝，与「假玻璃降级」冲突。

### 4. 中心 emoji 徽章

- **决策**：`_VsBadge` 显示 emoji（默认 `✨`），白/半透明圆形容器；`IgnorePointer` 穿透点击至下方色带。
- **理由**：零 asset 成本；分享截图稳定；后续可换 `assets/ucg/vs_sparkle.png` 而不改 API。
- **备选**：保留 "VS" 文字 — 用户已选 emoji。

### 5. 点击热区

- **决策**：维持 pivot 已实现的 per-side `GestureDetector`，热区 = `_GlassSide` 宽度（含 `minDisplayRatio` 钳制）。
- **理由**：与视觉色带一致，无需再改逻辑。

### 6. 论点区

- **决策**：单条论点 `primary @ 5%` 圆角 pill（radius ~12）；「展开 N 条论点」用 primary 色文字链；输入区 hint 色对齐 compose token。
- **理由**：统一但不叠加 blur。

### 7. 分享离屏布局

- **决策**：`UcgDebateShareLayout` 根节点改为 `UcgFeedFakeGlassPanel` 包裹话题 + VS + 论点摘要；背景不再用裸 `Material(color: white)`。
- **理由**：fluwx 封面与 App 内认知一致；PNG 不依赖 blur。

### 8. Web 降级

- **决策**：假玻璃路径不调用 `BackdropFilter`；Web 与 Native 同一套 widget 树，无需 `kIsWeb` 分支（除非实测需关阴影）。
- **理由**：降级策略是「不用 blur」而非「Web 再降一级」。

## Risks / Trade-offs

- **[Risk] 假玻璃在浅 shell 上边界弱** → 白边 alpha 提至 ~0.82；必要时 `showBorder` 双层。
- **[Risk] 马卡龙底 + 文字对比不足** → 选项用深灰字；百分比用 sticker badge。
- **[Risk] emoji 跨平台字形差异** → 分享图验收 iOS/Android/Chrome；预留 PNG fallback 常量。
- **[Risk] spec 与 pivot 归档顺序** → 本 change 独立 delta；收版时 `sync_specs_to_version` 合并两条 change 或先 pivot 后 glass。

## Migration Plan

1. 实现 `UcgFeedFakeGlassPanel` + token。
2. 替换 `UcgDebateFeedCard` 容器；微调 `ucg_square_tab` 若仍有裸 `UcgSurfaceCard`。
3. 重写 `UcgDebateVsBar` 视觉（去 blur、马卡龙、emoji）。
4. 论点 block 轻 tint；`UcgDebateShareLayout` 对齐。
5. Chrome 手工：推荐/关注滚动、投票、分享预览 PNG。
6. 与 `ucg-debate-pivot` §12 联调一并验收后分别或合并归档。

## Open Questions

- 中心 emoji 最终用 `✨` 还是育儿向 `🍼` — 实现默认 `✨`，产品可一行改常量。
- 个人时间线是否略降阴影 — 当前与 Feed 同款；若反馈太花再拆 `visualDensity` 参数。
