## MODIFIED Requirements

### Requirement: Predict tier chrome SHALL expose only Free and Pro

When bound smart-prediction「接下来3小时」shows a tier suffix (or the full-screen tier wall), the client MUST use exactly one of：`· 免费版` / `· Pro版`, choosing Pro when `predict_capability_pro` is time-valid unlocked, otherwise Free. The client MUST NOT show「间隔版」「基础版」or VIP-as-tier copy. While catalog/Pro eligibility needed for the suffix is still loading (syncing), the client MUST show a non-final syncing placeholder that MUST NOT open the wall as if settled, and MUST NOT await VIP status for that decision. When the suffix is **ready**（免费版 or Pro版, not syncing）, tapping **anywhere on the next-3-hours card**（title「接下来3小时」、suffix text, optional upgrade icon, body）MUST open the two-tier Free/Pro wall with `initialTier` matching the current suffix；this MUST apply equally when the current suffix is Pro版（Pro users MAY browse Free）. When the current ready suffix is **免费版**, the client MUST render Material `Icons.upgrade` immediately adjacent to the free-tier suffix label；when the suffix is Pro版 or syncing, the client MUST NOT show `Icons.upgrade`. The wall MUST remain a two-tier explanation surface (not a three-tier VIP wall).

3h 档位 MUST 仅为免费版/Pro版；MUST NOT 出现间隔/基础/VIP 档；syncing 占位 MUST NOT 开墙且 MUST NOT 依赖 VIP settle；非 syncing 时 **整卡**（含 Pro）MUST 开两档墙；免费版后缀旁 MUST 展示 `Icons.upgrade`，Pro/syncing MUST NOT 展示。

#### Scenario: Pro 优先

- **WHEN** `predict_capability_pro` 有效开通
- **THEN** 后缀 MUST 为「· Pro版」

#### Scenario: 非 Pro 为免费版

- **WHEN** Pro 未开通且 catalog/eligibility 已就绪
- **THEN** 后缀 MUST 为「· 免费版」

#### Scenario: 免费版展示 upgrade 图标

- **WHEN** 后缀为「· 免费版」且非 syncing
- **THEN** UI MUST 在该后缀旁展示 `Icons.upgrade`

#### Scenario: Pro 不展示 upgrade 图标

- **WHEN** 后缀为「· Pro版」
- **THEN** UI MUST NOT 展示 `Icons.upgrade`

#### Scenario: 免费整卡开墙

- **WHEN** 后缀为「· 免费版」且用户点击三小时卡正文或标题区
- **THEN** 客户端 MUST 打开免费/Pro 两档墙且初始档为免费版

#### Scenario: Pro 整卡也开墙

- **WHEN** 后缀为「· Pro版」且用户点击三小时卡正文或标题区
- **THEN** 客户端 MUST 打开免费/Pro 两档墙且初始档为 Pro版

#### Scenario: syncing 不可开墙

- **WHEN** 档位 chrome 仍为 syncing 占位
- **THEN** 点击三小时卡任意区域 MUST NOT 打开两档墙
