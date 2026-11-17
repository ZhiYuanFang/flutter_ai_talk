## Context

两档墙 Pro 卡外脚（`_FooterStatusLabel`）当前仅展示「敬请期待」或「正在使用」。`predict-pro-idea-wall` 已规定本版无支付/试用 CTA；卡内有付费意愿小字但无金额。catalog `predict_capability_pro.products[]` 已含 `priceFen`。基线对照 `openspec/specs/v2.2.1.md`；叠在 `predict-pro-idea-wall` 之上。

## Goals / Non-Goals

**Goals:**

- Pro「敬请期待」同行后追加 catalog 月价小字 `¥x/月`。
- 无可用价时隐藏小字。
- 保持脚为不可点状态标签。

**Non-Goals:**

- 恢复墙内支付 / 试用 / 邀请开通。
- 按 `durationDays` 推导「年/永久」等周期文案。
- 改想法区、Sheet、基础版脚、「正在使用」脚。
- 新 API / 本地写死金额。

## Decisions

1. **展示位置**  
   - 「敬请期待」与价格**同一行**（主文案后空开 + 小字）。  
   - 备选「下方另起一行」已否：产品要「后面」。

2. **文案形态**  
   - `¥{yuan}/月`；`/月` **写死**。  
   - 元字符串对齐现有习惯：整数可去小数（如 `¥19/月`），非整数两位（如 `¥19.90/月`）。  
   - 可复用/薄封装 `FeatureCatalogItem` 分→元逻辑，**禁止**硬编码具体数字。

3. **数据源与闸**  
   - 仅当 `resolvePredictTierFooter == comingSoon` 且 `pro?.defaultProduct?.priceFen > 0` 时拼 hint。  
   - 否则 `priceHint` 为空，UI 不渲染小字。

4. **UI 组件**  
   - 扩展 `_FooterStatusLabel`：`label` + 可选 `priceHint`；`Row`/`RichText` 居中；小字约 11–12sp、`onSurface` 略降 alpha，**不得**用档位 accent 当价色、**不得** InkWell。  
   - 固定高度 52 若挤：可略增或缩小字距；不得改成可点按钮 chrome。

5. **规格归属**  
   - 改 `predict-capability-tier-wall` 脚需求；不新开 capability。

## Risks / Trade-offs

- [SKU 实际非月付但文案写 /月] → 产品已接受写死；运营须保证 Pro 售价叙事为月付。  
- [catalog 未下发 products] → 隐藏小字，脚仍「敬请期待」。  
- [用户误认可点支付] → 保持非按钮形态 + 无 onTap；spec 明确 MUST NOT CTA。

## Migration Plan

- 纯客户端展示；无数据迁移。回滚：去掉 `priceHint` 即可。

## Open Questions

- （已定）同行；`/月` 写死；无价隐藏。
