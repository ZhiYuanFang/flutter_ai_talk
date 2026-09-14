## Context

`AiAnalysisScreen` Hub 用 `_HubGlassCard` 展示喂养 / 成长入口。blurb 现为中性介绍 + `fieldFill` 白底；剩余天数在 `metaLines`；标题与 body 多用 `onGlass` / `primary`。用户要模拟结果样张驱动转化，并统一功能色。

## Goals / Non-Goals

**Goals:**

- 两卡模拟样张（≤50 字、emoji、关键字加粗）+ 浅 accent 底
- 模拟角标贴在**样张浅色圆角底外侧左上**（玻璃卡内、标题下），非整卡外侧
- 样张正文 / 角标字色加深（实色或略压黑），保证浅底上可读
- 剩余天数到标题右侧小字
- 卡内文案与喂养资格进度跟 accent

**Non-Goals:**

- 不改子页业务 / 开通弹窗逻辑
- 不拉取真实 daily / 轨迹结果作样张（固定营销文案）
- 不改 AppBar「AI分析」页级 chrome 色

## Decisions

1. **模拟文案（定稿草案，实现可常量）**  
   - 喂养：`🍼 近2日夜醒偏多，今日留意**喂养间隔**与精神状态✨`（加粗「喂养间隔」）  
   - 成长：`📈 未来7天或迎**身高冲刺**，注意补钙与户外☀️`（加粗「身高冲刺」）  
   用 `Text.rich` / `TextSpan`，不上 markdown 包。

2. **样张底**：`accent.withValues(alpha: ~0.12)` 圆角，替代 `fieldFill`。样张正文用加深后的 accent（如 `Color.lerp(accent, black, 0.18)` 或等价），**不得**仅用高透明 alpha 导致发灰。

3. **角标位置**：在玻璃卡内部、标题行之下；紧贴浅色样张面板**外侧左上**（`Column`：角标 → 间距 → DecoratedBox 样张）。**不得**放在整张玻璃卡外侧。文案含「模拟内容」与「你可以得到这样的效果」；角标字色同加深 accent。

4. **时效**：`featureHubEntitlementRemainingCopy` 结果放标题行右侧小字（chevron 左侧）；清空原 entitlement `metaLines`（「每日仅支持…」若仍启用可留 meta 或一并旁置——当前代码注释关闭，本 change 不强制恢复）。

5. **跟色范围**：标题、样张、角标、时效小字、`_hubMuted` / 开通心跳 / 进入提示 → accent（心跳可继续动画，色改 accent）。  
   `FeedingEligibilityProgressText`：增加可选 `accent`（或 `Color? emphasis`），Hub 传入功能色；缺省仍 `colorScheme.primary` 免伤其它调用方。

6. **展示态**：未合格 / 未开通 / 已开通均展示模拟样张 + 角标。

## Risks / Trade-offs

- [模拟文案被当成真实结果] → 角标明示「模拟内容」  
- [emoji 在部分字体回退] → 可接受  
- [资格组件 API 扩展] → 可选参数，向后兼容

## Migration Plan

纯客户端；回滚还原 blurb / meta / 颜色。

## Open Questions

无（资格进度跟色、角标跟 accent；角标贴样张外非整卡外；样张字色加深已定）。
