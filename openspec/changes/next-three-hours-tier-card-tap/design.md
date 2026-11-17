## Context

`_NextThreeHoursTimeline`（`smart_prediction_screen.dart`）已展示 `· 免费版` / `· Pro版` / syncing 占位，并用内层 `InkWell` **仅**包住后缀文案调用 `showPredictCapabilityTierWall`。`align-go-free-predict-retire` 要求「卡上除版本文案外不得另设点击导航」，导致正文与标题六字无反馈。产品现要求扩大热区并给免费档 `Icons.upgrade`；并明确 **Pro 时整卡也开墙**（浏览两档，非仅升级路径）。

## Goals / Non-Goals

**Goals:**

- 非 syncing：整卡单击打开两档墙，`initialTier` 对应当前后缀。
- 免费版：后缀旁固定 `Icons.upgrade`；Pro / syncing 无该图标。
- 去掉「仅后缀下划线」作为唯一可发现热区的依赖（整卡可点后后缀可不强求 underline）。
- 规格 delta 覆盖 `predict-free-pro-chrome` 与 `smart-prediction-page`，supersede「ONLY suffix tappable」。

**Non-Goals:**

- 不改墙内 carousel、底栏试用/支付、eligibility。
- 不恢复 AI分析、不恢复进喂养。
- 不新增 debug tag / HTTP / 原生依赖。
- 不改事件瀑布流卡或其它档位入口。

## Decisions

1. **Pro 整卡也开墙**  
   - 选定：免费与 Pro 在 `canOpenWall` 时行为一致——整卡开墙。  
   - 理由：用户已确认议题「Pro 时整卡是否也开墙」并纳入本提案；Pro 用户仍可浏览免费档说明。  
   - 备选（未选）：仅免费整卡可点、Pro 仅后缀或不可点——与「整卡开墙」产品表述不一致。

2. **热区实现**  
   - 选定：外层 `InkWell`/`Material` 包住整张 DecoratedBox 内容（或整卡 Padding 区域）；内层去掉单独后缀 InkWell，避免嵌套抢手势。  
   - `onTap`：仅当 `labelKind != syncing` 时调用 `showPredictCapabilityTierWall`；`initialTier` 仍用 `predictCapabilityTierCarouselIndex(labelKind)`。  
   - 备选：外层 GestureDetector + 后缀保留 InkWell——易双触发，弃用。

3. **Icons.upgrade**  
   - 选定：免费档在后缀 `Text` 旁放 `Icon(Icons.upgrade, size: ~与字号协调)`，颜色跟 `titleStyle` / primary；与文案同一 `Row`。  
   - Pro 与 syncing：**不得**渲染该 Icon。  
   - 备选：用自定义 SVG——无必要，产品指定 Material icon。

4. **视觉**  
   - 整卡可点后：后缀 **可不** 再设 `TextDecoration.underline`（减少「只有字能点」误导）；水波纹由整卡 InkWell 提供。  
   - 不引入额外卡片阴影/徽章叠层。

## Risks / Trade-offs

- [误触开墙] 用户滑列表时轻触 3h 卡即弹墙 → 接受；墙有关闭控件；若反馈过强可后续加长按/仅标题行（本变更不做）。  
- [与旧 delta 冲突] `align-go-free` / 旧 `tier-wall` 写「ONLY suffix」→ 本变更 MODIFIED Requirement 明确 supersede。  
- [syncing 闪点] phase 从 syncing→ready 瞬间可点 → 既有 settle 语义，行为正确。

## Migration Plan

- 纯客户端 UI；发版即生效，无需迁移缓存。  
- 回滚：恢复后缀-only InkWell 并去掉 upgrade Icon。

## Open Questions

- （无）Pro 整卡开墙与 `Icons.upgrade` 已在提案输入中锁定。
