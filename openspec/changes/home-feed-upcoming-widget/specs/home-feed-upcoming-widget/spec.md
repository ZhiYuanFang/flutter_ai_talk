## ADDED Requirements

### Requirement: Home screen widget SHALL show upcoming feed events on Android and iOS

The client SHALL provide standard system home screen widgets on **Android and iOS** in three sizes corresponding to `systemSmall` / `systemMedium` / `systemLarge` (2×2, 4×2, 4×4). The user MUST select widget size when adding from the OS picker. Widget content MUST be driven by a JSON payload written from Flutter via `home_widget`; native widget code MUST NOT initiate HTTP or WebSocket.

客户端 MUST 在 Android 与 iOS 提供标准三尺寸桌面小组件；数据来自 Flutter 写入的 JSON；native MUST NOT 自行请求网络。

#### Scenario: 用户添加 medium 小组件

- **WHEN** 用户在系统小组件库选择胖宝 medium 尺寸并添加
- **THEN** 桌面 MUST 展示 medium 布局（头部 + 最多 3 内容行）
- **AND** payload MUST 包含 `widgetKind: medium`

#### Scenario: Web 平台无小组件

- **WHEN** 应用在 Web 运行
- **THEN** 客户端 MUST NOT 注册或展示桌面小组件

### Requirement: Widget header SHALL display baby nickname and month age

When logged in with usable baby profile data, the widget MUST show a header line formatted as `{nickname} · {ageText}` (e.g. 「宥宥 · 6个月啦」) without literal bracket characters. Nickname MUST truncate with ellipsis beyond 6 characters; empty nickname MUST fall back to 「宝宝」. Age text MUST use 「不满1个月啦」 for 0 complete months, 「{n}个月啦」 for 1–11 months, and 「{y}岁啦」 or 「{y}岁{m}个月啦」 for 12+ months. Native rendering SHOULD recompute age from `birthDate` at display time.

已登录且存在宝宝资料时，小组件顶部 MUST 展示昵称与月龄文案；native SHOULD 按 birthDate 动态重算月龄。

#### Scenario: 有效昵称与 6 月龄

- **WHEN** payload header 含 nickname「宥宥」且 birthDate 对应当前 6 个完整月
- **THEN** 头部 MUST 展示「宥宥 · 6个月啦」

#### Scenario: 未登录无头部

- **WHEN** payload `state` 为 `empty` 且用户未登录
- **THEN** 小组件 MUST NOT 展示宝宝头部
- **AND** MUST 展示「打开胖宝记录」

### Requirement: Widget rows SHALL prioritize active timing then global nextAt

Content row budget MUST be: small=1, medium=3, large=6 including active and predict rows. Active timing rows MUST appear before predict rows. Predict rows MUST be chosen by global ascending `nextAt` among predictable events. Each row MUST show event name, brand color accent, and time phrase computed at native render from absolute `startAt` or `nextAt`.

行数 MUST 按尺寸分配；active 优先；predict 按 nextAt 全局排序；相对时间 MUST native 渲染时计算。

#### Scenario: medium 含一条 active 两条 predict

- **WHEN** 存在 1 条进行中计时且至少有 2 条可预测事件
- **THEN** medium 小组件 MUST 展示 1 active + 2 predict 共 3 行

#### Scenario: small 仅有 active

- **WHEN** small 小组件且存在进行中计时
- **THEN** MUST 仅展示 1 条 active 行
- **AND** MUST NOT 展示 predict 行

### Requirement: Widget visual style SHALL use fake-glass cute macaron tokens

Widget UI MUST follow fake-glass macaron cute style aligned with `UcgFeedFakeGlassPanel` / brand shell `#B8DFF2`: semi-transparent white gradient fill, white border (~82% alpha), soft shadow, corner radius ~18, event row left color bar ~3dp. Widget MUST NOT require `BackdropFilter` blur.

小组件 MUST 采用假玻璃马卡龙可爱风；MUST NOT 依赖 BackdropFilter。

#### Scenario: 事件行色条

- **WHEN** predict 行含 event color `#E88BB0`
- **THEN** 行左侧 MUST 展示约 3dp 宽色条

### Requirement: Widget states loading and empty SHALL show prescribed copy

When history depth prefetch is in progress and prediction is not yet ready, payload `state` MUST be `loading` and body MUST show 「正在准备数据…」; header MAY show when baby profile exists. When user is not logged in OR logged in with no active and no predictable rows after prefetch, `state` MUST be `empty` and body MUST show 「打开胖宝记录」. Tapping the widget MUST open the app (login if logged out, home if logged in).

loading 与 empty MUST 使用规定文案；点击 MUST 打开 App。

#### Scenario: 首次预拉 loading

- **WHEN** 小组件已添加且 `ensureWidgetHistoryDepth` 进行中
- **THEN** payload MUST 为 `loading`
- **AND** 主体 MUST 展示「正在准备数据…」

#### Scenario: 登出 empty

- **WHEN** 用户登出
- **THEN** Flutter MUST 写入 `empty` payload
- **AND** 小组件 MUST NOT 继续展示上一用户事件行

#### Scenario: 点击打开 App

- **WHEN** 用户点击小组件 empty 态
- **THEN** App MUST 打开；未登录 MUST 进入登录流程

### Requirement: Widget payload refresh SHALL trigger on history and profile changes

Flutter MUST recompute prediction and call `HomeWidget.updateWidget` after: history create/update/delete (including WS merge), successful widget history depth prefetch, baby profile save, login success, and logout (empty). Widget refresh MUST NOT run automatically from provider construction alone.

历史/资料/登录态变更 MUST 触发 updateWidget；provider 构造 MUST NOT 自动刷新。

#### Scenario: 新增喂养记录后刷新

- **WHEN** 用户成功新增一条历史记录
- **THEN** 客户端 MUST 在合理延迟内 updateWidget 且 predict 行 MUST 反映新 lastAt

#### Scenario: 登出清除

- **WHEN** session 变为未登录
- **THEN** MUST updateWidget 为 empty
- **AND** MUST NOT 保留旧用户 nickname 于 header
