## ADDED Requirements

### Requirement: Next-3-hours title SHALL show predict tier suffix

When the bound smart-prediction「接下来3小时」card is shown and entitlement settle phase is **ready**, the title row MUST append a bold suffix at the same font size as「接下来3小时」, using exactly one of：`· 间隔版` / `· 基础版` / `· Pro版`, chosen by：effective `predict_capability_pro` → Pro版；else effective basic **or** `isVip` → 基础版；else → 间隔版. While settle phase is **syncing**, the client MUST NOT show a final tier suffix as if ready；it MUST show a syncing placeholder（e.g. `· 同步中`）that MUST NOT open the tier wall, **or** omit the tappable suffix until ready. Auth-guest chrome without the 3h card MUST NOT require the suffix.

已绑定 3 小时卡在 settle ready 时 MUST 在标题后加粗同字号展示 `· 间隔版|基础版|Pro版`（pro→basic∨VIP→间隔）；syncing MUST NOT 落最终档，MUST 用不可点同步占位或暂不展示可点后缀。

#### Scenario: VIP 标题为基础版

- **WHEN** settle ready、用户 isVip、且无人购 pro 有效
- **THEN** 标题后缀 MUST 为 `· 基础版`

#### Scenario: 无人权益非 VIP 为间隔版

- **WHEN** settle ready、非 VIP、basic/pro 均无效
- **THEN** 标题后缀 MUST 为 `· 间隔版`

#### Scenario: syncing 不落最终档

- **WHEN** settle 为 syncing
- **THEN** UI MUST NOT 将可点最终档后缀当作已结案展示

### Requirement: Tier suffix SHALL open fullscreen three-tier wall

Tapping the tier suffix（when ready）MUST present a fullscreen overlay/dialog with a close control at the top-trailing corner. The wall MUST contain exactly three predict tiers in order：间隔版、基础版、Pro版. The client MUST use `carousel_slider`（or the pinned package equivalent）so the center card is enlarged and neighboring cards are partially visible, and the user MUST be able to swipe between tiers. The wall MUST open with `initialPage` matching the current title tier. The wall MUST NOT list non-predict hub features.

点版本文案 MUST 打开仅含预测三档的全屏墙；MUST 用 carousel_slider 中卡放大两侧露出；MUST 以当前档为初始页；右上 MUST 可关闭。

#### Scenario: 打开停在当前档

- **WHEN** 标题为 `· 基础版` 且用户点后缀
- **THEN** 墙 MUST 全屏展示且初始中心卡 MUST 为基础版

### Requirement: Tier card chrome SHALL use glass detail and capability color

Each tier card MUST render an upper glassmorphism detail panel（rounded）tinted with that tier’s color：间隔版 MUST use theme primary；基础/Pro MUST use catalog feature color when present else primary. Basic/Pro MUST show catalog `logo` image when the URL is non-empty；间隔版 MUST NOT show a logo/image region. Description/title copy MAY come from catalog for basic/pro and from client copy for 间隔版. Below the detail panel, the card MUST show a separate rounded glass footer control area whose background/text follows the tier color rules above.

每卡上玻璃详情随档色；间隔主题色且 MUST NOT 出图；基础/Pro 有 logo 才展示图；下玻璃底栏随档色。

#### Scenario: 间隔版无图

- **WHEN** 用户滑到间隔版卡
- **THEN** UI MUST NOT 展示间隔版功能图/logo 区域

### Requirement: Tier footer SHALL reflect unlock and VIP rules

The footer label and interactivity MUST follow：

- **间隔版**：if `isVip` →「VIP已开通」not tappable；else → non-purchase copy such as「当前节奏」/「已启用」not tappable（MUST NOT offer 开通试用/立即开通 for 间隔版）.
- **基础版**：if basic entitlement effective →「已开通」not tappable；else if `isVip` →「VIP已开通」not tappable；else if trial available →「开通试用」tappable and MUST call `POST …/feature/trial/start` for `predict_capability_basic` in-wall；else MAY show「立即开通」navigating to unlock hub.
- **Pro版**：if pro entitlement effective →「已开通」not tappable；otherwise（including VIP and non-VIP without pro）→「暂未开放」not tappable（MUST NOT start pro trial or payment from this footer while pro is not launched）.

底栏 MUST 按上表；非 VIP 基础试用 MUST 墙内直调 trial；Pro 在未人购有效时（含 VIP）MUST「暂未开放」。

#### Scenario: 非 VIP 试用基础

- **WHEN** 非 VIP、basic 未开通且 trialAvailable
- **AND** 用户在基础版卡点「开通试用」
- **THEN** 客户端 MUST 调用 basic `trial/start`
- **AND** 成功后 MUST 刷新 catalog 使基础档变为已开通语义

#### Scenario: VIP 时 Pro 暂未开放

- **WHEN** 用户 isVip 且 pro 人权益无效
- **AND** 中心卡为 Pro版
- **THEN** 底栏 MUST 为「暂未开放」且不可点
- **AND** MUST NOT 显示「VIP已开通」于 Pro 底栏

#### Scenario: VIP 时基础 VIP已开通

- **WHEN** 用户 isVip、basic 人权益无效
- **AND** 中心卡为基础版
- **THEN** 底栏 MUST 为「VIP已开通」且不可点
