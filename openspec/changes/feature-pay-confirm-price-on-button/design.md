## Context

开通中心 `_openPaymentDialog` 现用 `showGlassConfirmDialog`，金额在 message，确认键仅「去支付」。`confirmLabel` 仅为 String，无法做右侧小字括号价。同仓已有 `showGlassDialog` + 自定义 content（如 compose 退出）先例。

## Goals / Non-Goals

**Goals:**

- 支付确认：确认键 `去支付` + 右侧小字 `(priceLine)`；正文不再写「价格：」。
- 仅开通中心支付路径；玻璃视觉与现 confirm 对齐。

**Non-Goals:**

- 不修改 `showGlassConfirmDialog` 公共签名。
- 不改广告确认、不改卡片 CTA 价签、不改支付/履约逻辑。

## Decisions

### D1：支付专用 showGlassDialog（方案 C）

- `_openPaymentDialog` 改为 `showGlassDialog<bool>`，content 仿 confirm 布局（标题 / 说明 / 取消+Filled 确认）。
- 否决：单行拼接同字号；否决：给通用 confirm 加 Widget 参数（影响面大）。

### D2：确认键价形态

- `Row(mainAxisSize: min)`：主文「去支付」（Web：「仅 App 可支付」）+ 小字 ` ($priceLine)`。
- `priceLine`：预测 `¥x/个`，其它 `¥x`（既有 `formatVipFenYuan`）。
- 小字：约 11–12，`onPrimary` 降 alpha。

### D3：正文去重

- 说明仅描述开通效果（+1 条 / 有效期），不重复价格行。

## Risks / Trade-offs

- [窄屏确认键过长] → 小字 + compact padding；极端价串仍可换行由 FilledButton 约束。
- [与卡片价重复] → 产品接受（进弹窗前 / 确认时各一眼）。

## Migration Plan

- 随客户端发版；无数据迁移。

## Open Questions

- 无。
