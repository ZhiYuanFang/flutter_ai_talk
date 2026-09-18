## Context

`unlock-hub-vip-sticky` 已将已 VIP 主标题改为「VIP · 剩余…」，但未开通 CTA、过期文案、购买页区块与 `displayUnlockMethod('vip')` 仍返回「月卡」。

## Goals / Non-Goals

**Goals:**

- 用户可见字符串统一用 VIP 称呼订阅权益。
- 规格 delta 与实现一致。

**Non-Goals:**

- 不改 SKU 时长、价格、支付、服务端字段名。
- 不强制清理历史 OpenSpec change 文档里的「月卡」叙述。
- 不新建测试。

## Decisions

### D1. 文案映射表（唯一真相）

| 旧 | 新 |
|----|----|
| 开通月卡解锁所有功能 | 开通 VIP 解锁所有功能 |
| 去开通月卡 | 去开通 VIP |
| 开通月卡（副文） | 开通 VIP |
| 月卡已过期 | VIP 已过期 |
| 月卡包含的更多功能 | VIP 包含的更多功能 |
| unlockMethod `vip` →「月卡」 | 「VIP」 |

### D2. 注释可选

代码注释中的「月卡」可顺手改为 VIP，非验收项。

## Risks / Trade-offs

- [用户仍看到 30 天有效期] → 可接受；VIP 不等于「终身」，副文继续写天数。
- [服务端/运营后台仍写月卡] → 本 change 只约束 App 展示。

## Open Questions

无。
