## ADDED Requirements

### Requirement: Settings center SHALL show unlocked capabilities under avatar with remaining days

Below the baby avatar in the settings center profile card, the client MUST show a compact summary of unlocked commercial capabilities and remaining days (or「永久」when `expiresAt` is permanent). Tapping this summary MUST navigate to the feature unlock hub. When `isVip` is true, the summary MUST prefer「月卡 · 剩余 X 天」(derived from VIP `expireAt`) over listing every feature. When not VIP, the summary MUST reflect device_no entitlements (e.g. count + nearest expiry, or empty CTA「暂无已开通能力 · 去开通」). The summary tap target MUST be split from the baby-edit InkWell so tapping the summary MUST NOT open `/settings/baby`, and tapping baby identity fields MUST still open baby edit.

设置中心头像下方 **必须** 展示已开通能力与剩余天数摘要；点击 **必须** 进入开通中心。VIP 时 **必须** 优先「月卡 · 剩余 X 天」。摘要点击 **必须** 与宝宝编辑 InkWell 分离。

#### Scenario: VIP 优先月卡文案

- **WHEN** 用户已登录绑定且 `isVip` 为 true、VIP 未过期
- **THEN** 头像下摘要 MUST 展示「月卡 · 剩余 X 天」类文案
- **AND** 点击该摘要 MUST 进入开通中心
- **AND** MUST NOT 打开宝宝编辑页

#### Scenario: 非 VIP 展示设备权益摘要

- **WHEN** 用户非 VIP 且存在至少一项未过期的 device 权益
- **THEN** 摘要 MUST 反映已开通能力与剩余/永久信息
- **AND** 点击 MUST 进入开通中心

#### Scenario: 空态去开通

- **WHEN** 用户非 VIP 且无有效设备权益
- **THEN** 摘要 MUST 展示可点击的空态去开通指引（如「暂无已开通能力 · 去开通」）

#### Scenario: 宝宝资料区仍进编辑

- **WHEN** 用户点击头像卡内昵称/性别/生日等资料区域（非开通摘要）
- **THEN** 客户端 MUST 导航至 `/settings/baby`（或既有宝宝编辑路由）
