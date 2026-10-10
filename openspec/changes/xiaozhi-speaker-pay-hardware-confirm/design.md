## Context

小智音箱管理页（`xiaozhi_speaker_screen.dart`）已有：
- 顶部静态自购说明（教育）；
- 可售时「永久开通」主 CTA，当前直接调用 `_purchasePermanent`；
- 「体验已用完」添加路径经 `showGlassConfirmDialog` 后同样进入 `_purchasePermanent`。

支付实现已在 `XiaozhiMcpPaymentService`；本变更只加付款前 UX 闸门。弹框须符合 `openspec/project.md` 玻璃确认约定（本确认无 TextEditingController）。

## Goals / Non-Goals

**Goals:**

- 任何调起永久开通支付前，用户必须看到并可取消的硬件免责确认。
- 主 CTA 与体验用尽引导开通路径行为一致（不漏网）。
- 文案清晰：须自行购机；本次付款不含音箱实体。

**Non-Goals:**

- 不改订单/验单/SKU/划线价。
- 不删除或改写页面静态自购说明与效果卡。
- 不要求服务端记录「已确认」；客户端会话内弹窗即可。
- 不做「不再提示」勾选持久化。

## Decisions

### D1：确认挂在 `_purchasePermanent` 入口

- **选择**：在 `_purchasePermanent` 开头 `await showGlassConfirmDialog`，确认后才 `setState(_paying)` 并调用 payment service。
- **理由**：单一闸门覆盖主按钮与体验用尽路径，避免漏改。
- **备选**：仅包主按钮 onPressed → 体验用尽路径可能绕过；或把免责写进体验用尽弹窗 → 双入口文案分叉难维护。

### D2：体验用尽路径允许连续两层确认

- 第一层：体验用尽 / 是否去开通；第二层：硬件免责。
- **接受**略繁琐，换取语义分离与实现简单。
- **不**合并两层文案（避免改动既有体验用尽话术职责）。

### D3：文案与按钮

| 槽位 | 文案 |
|------|------|
| title | `开通前确认` |
| message | `使用本功能前，须自行购买小智音箱。本次付款仅开通 App 内绑定与语音记喂养能力，不包含音箱实体。` |
| confirmLabel | `继续开通` |
| cancelLabel | `取消` |

取消或关闭 → 立即 return，不置 `_paying`、不建单。

### D4：与静态说明并存

顶部自购条保留；确认是付款瞬间的知情同意，不替代页面教育。

## Risks / Trade-offs

- [体验用尽连弹两次] → 接受；若后续抱怨再合并文案。
- [用户以为确认即扣款] → confirm 用「继续开通」而非「付款」，进入后再走支付宝/IAP 系统确认。
- [与未归档 app-binding 叠合] → 本变更只改 UI 闸门；归档时 delta 并入 `xiaozhi-speaker-unlock`。

## Migration Plan

- 纯客户端热更/发版即可；无数据迁移。
- 回滚：去掉确认调用即可恢复直付。

## Open Questions

- （无）文案与挂点已在 explore 收敛；实现期若产品要改 confirmLabel 可只改常量。
