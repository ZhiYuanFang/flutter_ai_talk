## MODIFIED Requirements

### Requirement: Predict tier chrome SHALL expose only Free and Pro

When bound smart-prediction「接下来3小时」shows a tier suffix (or the full-screen tier wall), the client MUST use exactly one of：`· 基础版` / `· Pro版`, choosing Pro when `predict_capability_pro` is time-valid unlocked, otherwise the client free-tier label shown as **基础版**. The client MUST NOT show「免费版」「间隔版」or VIP-as-tier copy. While catalog/Pro eligibility needed for the suffix is still loading (syncing), the client MUST show a non-final syncing placeholder that MUST NOT open the wall as if settled, and MUST NOT await VIP status for that decision. When the suffix is **ready**（基础版 or Pro版, not syncing）, tapping **anywhere on the next-3-hours card**（title「接下来3小时」、suffix text, body）MUST open the two-tier wall with `initialTier` matching the current suffix；this MUST apply equally when the current suffix is Pro版（Pro users MAY browse 基础版）. The client MUST NOT render Material `Icons.upgrade`（or equivalent upgrade affordance）beside the 基础版 suffix. The wall MUST remain a two-tier explanation surface (not a three-tier VIP wall).

3h 档位 MUST 仅为「基础版」/「Pro版」；MUST NOT 出现「免费版」/间隔/VIP 档；syncing 占位 MUST NOT 开墙且 MUST NOT 依赖 VIP settle；非 syncing 时 **整卡**（含 Pro）MUST 开两档墙；MUST NOT 在基础版后缀旁展示 `Icons.upgrade`。

#### Scenario: Pro 优先

- **WHEN** `predict_capability_pro` 有效开通
- **THEN** 后缀 MUST 为「· Pro版」

#### Scenario: 非 Pro 为基础版

- **WHEN** Pro 未开通且 catalog/eligibility 已就绪
- **THEN** 后缀 MUST 为「· 基础版」

#### Scenario: 基础版不展示 upgrade 图标

- **WHEN** 后缀为「· 基础版」且非 syncing
- **THEN** UI MUST NOT 在该后缀旁展示 `Icons.upgrade`

#### Scenario: Pro 不展示 upgrade 图标

- **WHEN** 后缀为「· Pro版」
- **THEN** UI MUST NOT 展示 `Icons.upgrade`

#### Scenario: 基础版整卡开墙

- **WHEN** 后缀为「· 基础版」且用户点击三小时卡正文或标题区
- **THEN** 客户端 MUST 打开两档墙且初始档为基础版（`PredictCapabilityTier.free`）

#### Scenario: Pro 整卡也开墙

- **WHEN** 后缀为「· Pro版」且用户点击三小时卡正文或标题区
- **THEN** 客户端 MUST 打开两档墙且初始档为 Pro版

#### Scenario: syncing 不可开墙

- **WHEN** 后缀为同步中占位
- **THEN** 点击三小时卡 MUST NOT 打开两档墙
