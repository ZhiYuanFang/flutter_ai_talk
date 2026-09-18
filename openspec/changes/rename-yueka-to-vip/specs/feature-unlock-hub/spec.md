## MODIFIED Requirements

### Requirement: Unlock hub SHALL show unlocked state with method and hide CTAs

When a feature is effectively unlocked (`catalog.unlocked || isVip`), the unlock hub card MUST show「已开通」and a human-readable unlock method label, and MUST hide payment / ad / invite-code CTAs. Method labels MUST map: `payment`→支付开通, `ad`→看广告, `invite_code`→激活码, `vip`→VIP. If unlocked only via `isVip` without catalog unlockMethod, the displayed method MUST be「VIP」.

功能有效开通后 **必须** 展示「已开通」与开通方式并隐藏 CTA；仅 VIP 覆盖时方式 **必须** 为「VIP」（不得再展示「月卡」）。

#### Scenario: VIP 覆盖显示 VIP 方式

- **WHEN** 功能仅因 `isVip` 有效开通
- **THEN** 卡片 MUST 显示「已开通」且开通方式为「VIP」
- **AND** MUST NOT 显示「月卡」作为开通方式标签

### Requirement: Unlock hub SHALL offer VIP purchase entry and VIP page lists catalog titles

The unlock hub MUST show「开通 VIP 解锁所有功能」navigating to the existing VIP purchase page. The VIP purchase page MUST list more-features included with VIP from **catalog titles** (UCG eligibility MUST NOT appear as a VIP-included catalog row). User-visible copy on that entry and the purchase page section title MUST use「VIP」, MUST NOT use「月卡」.

开通中心底部 **必须** 进 VIP 购买页；入口与购买页区块标题 **必须** 使用 VIP 文案（不得使用「月卡」）；VIP 页 **必须** 列出 catalog 标题（不含 UCG 资格项）。

#### Scenario: 底栏开通文案为 VIP

- **WHEN** 用户未开通 VIP 且开通中心底栏可见
- **THEN** 主标题 MUST 为「开通 VIP 解锁所有功能」或等价以 VIP 命名的开通引导
- **AND** CTA MUST 为「去开通 VIP」或等价
- **AND** MUST NOT 出现「月卡」字样

#### Scenario: 购买页包含功能标题

- **WHEN** 用户打开 VIP 购买页且 catalog 有可列标题
- **THEN** 页面 MUST 展示这些标题作为 VIP 包含的更多功能
- **AND** 区块标题 MUST 使用「VIP 包含的更多功能」或等价 VIP 命名
- **AND** MUST NOT 使用「月卡包含的更多功能」
