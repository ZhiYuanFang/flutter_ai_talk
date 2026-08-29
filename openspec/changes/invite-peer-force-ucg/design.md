## Context

对照 Go `invite-peer-force-ucg`：邀请码身份化、预测三通道 +1、原力在 ucg、catalog `totalActivatableCount`、VIP 与永久开通解耦。Flutter 现有开通中心仍按「VIP/已开通则隐藏 CTA」「激活码全开」文案运作；UCG「我的」无邀请码与积分详情。

## Goals / Non-Goals

**Goals:**

- 个人中心：邀请码 + 详情；等级图标 → 积分详情（客户端算档位/距升级）。
- 开通中心：已激活 X / 已全部激活；未满则始终显示「现价 ̶原价̶ /个」与邀请码入口；月卡底栏悬浮并写明有效期。
- 预测使用锁：永久条数 OR VIP；展示「已激活」只看永久值 vs total。

**Non-Goals:**

- 不实现服务端；不改 UCG 入场门槛逻辑；不新建测试；不回填历史流水 UI 空态以外的假数据。

## Decisions

### D1：激活数文案

- `activated = allowedCount`（永久合成，≥0）；若 `totalActivatableCount > 0 && activated >= total` →「已全部激活」，否则「已激活 {activated} 个」。
- `allowedCount < 0`（若仍出现）不当作「已全部激活」库存态；本变更后预期不再由邀请产生。

### D2：VIP 不隐藏累加 CTA

- 预测功能卡：只要未全部永久激活，支付/邀请（及广告若仍启用）按钮保持可见，即使 `isVip`。
- 其它布尔 entitlement 功能：可继续「有效开通（含 VIP）则显示已开通」；与预测数量卡区分。

### D3：月卡底栏

- Hub 使用 `Scaffold` + `bottomNavigationBar` / 底部 `Stack` 悬浮月卡；文案含有效期（已 VIP 显示到期，未开通显示「开通后有效期 N 天」或价表 duration）。

### D4：数据源

- 邀请：cash `invite/mine`、`invite/invitees`。
- 积分：ucg ledger + profile `forceValue`；档位阈值保持与现 `UcgForceTierIcon` 一致，距升级客户端计算。

## Risks / Trade-offs

- [Go 未就绪] → 客户端可先按契约 mock 字段；联调以 Go apply 为准。
- [total=0] → 不显示「已全部激活」，避免误伤。
- [锁槽与 total 集合不同] → 产品确认故意解耦：锁=当前排序前 N 行，全部激活=字典非叶子 total；详见 change `prediction-lock-index-vs-nonleaf-total`（不按非叶子 eventId 绑槽）。

## Migration Plan

- 随 Go 部署后发版；无本地迁移。

## Open Questions

- 无。
