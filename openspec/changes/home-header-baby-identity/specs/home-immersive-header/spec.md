## ADDED Requirements

### Requirement: 喂养沉浸头 SHALL 展示宝宝身份横条

The feeding immersive header MUST NOT use the static title「喂养记录」as the primary heading. It SHALL show a horizontal identity strip: baby avatar, then a single text line of nickname and age separated by「 · 」, left-aligned and vertically centered within the header row. The combined text MUST use single-line trailing ellipsis (`TextOverflow.ellipsis` or equivalent) when space is insufficient. Empty nickname MUST fall back to「宝宝」; age text MUST use `formatBabyAgeText` (or equivalent). When baby profile is unavailable, the same fallbacks MUST apply.

喂养沉浸式头部 **不得** 以「喂养记录」作为主标题；**必须** 横向展示宝宝头像与合成文案「昵称 · 月龄」，左对齐且在头部行内纵向居中；空间不足时合成文案 **必须** 单行尾部省略。空昵称回退「宝宝」；月龄 **必须** 使用 `formatBabyAgeText`（或等价）；资料不可用时使用相同回退。

#### Scenario: 有宝宝资料时展示身份条

- **WHEN** 用户进入喂养页且 `settingsBabyProvider`（或等价）已提供可用宝宝资料
- **THEN** 沉浸头 MUST 显示该宝宝头像
- **AND** 文案 MUST 为「{昵称} · {月龄文案}」单行形式
- **AND** MUST NOT 再显示主标题「喂养记录」

#### Scenario: 超长昵称尾部省略

- **WHEN** 昵称与月龄合成文案宽度超出身份区可用宽度
- **THEN** 该文案 MUST 单行展示并以尾部省略号截断

#### Scenario: 资料缺失时的回退

- **WHEN** 宝宝资料尚未加载完成或昵称/生日不可用
- **THEN** 昵称侧 MUST 回退为「宝宝」（若昵称为空）
- **AND** 月龄侧 MUST 展示与 `formatBabyAgeText` 一致的回退文案（含「不满1个月啦」情形）

### Requirement: 仅头像可点进入设置

Only the baby avatar hit target on the feeding immersive header SHALL navigate to `/settings`. Tapping the nickname or age text MUST NOT open settings solely for that tap. Unauthenticated users MUST reach the settings shell the same way as the former top-right settings icon (direct navigation to `/settings` without an extra login gate on the avatar tap).

喂养沉浸头 **仅** 宝宝头像命中区 SHALL 导航至 `/settings`；点击昵称或月龄文案 **不得** 仅因此打开设置。未登录用户 MUST 与原右上设置齿轮一致，直达 `/settings` 壳，**不得** 因头像点击额外增加登录门闸。

#### Scenario: 点击头像进入设置

- **WHEN** 用户点击喂养沉浸头中的宝宝头像
- **THEN** 应用 MUST 导航至 `/settings`

#### Scenario: 点击文案不进入设置

- **WHEN** 用户点击身份条中的昵称或月龄文案区域（非头像）
- **THEN** 应用 MUST NOT 仅因此导航至 `/settings`

## MODIFIED Requirements

### Requirement: 沉浸式头部保留趋势与设置入口

The immersive header SHALL preserve a top-right navigation action for Trends with unchanged route `/trends`. The top-right Settings gear MUST NOT be shown; Settings entry SHALL be provided by tapping the baby avatar (see「仅头像可点进入设置」). 沉浸式头部必须在右侧保留趋势入口且路由仍为 `/trends`；**不得** 再展示右上设置齿轮；设置入口 **必须** 由点击宝宝头像提供。

#### Scenario: 点击趋势入口

- **WHEN** 用户点击沉浸式头部中的趋势入口
- **THEN** 应用必须导航至 `/trends`

#### Scenario: 右上无设置齿轮

- **WHEN** 用户查看喂养页沉浸式头部
- **THEN** UI MUST NOT 展示右上设置（齿轮）图标按钮
- **AND** 右侧 MUST 仍可进入趋势
