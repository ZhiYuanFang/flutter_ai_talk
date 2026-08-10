## ADDED Requirements

### Requirement: 可见页共享落库飞入编排

The client MUST use a single fly-animation implementation (center pop then shrink toward a landing point) for history landing feedback on both the feeding page and the smart prediction page. Each visible page MUST supply only a landing-target resolver (prepare + measure); the pages MUST NOT duplicate the animation motion logic. 客户端 MUST 用**同一套**飞入实现（屏中心放大后缩小落向落点）服务喂养页与智能预测页；各可见页 MUST 仅提供落点解析（prepare + measure），MUST NOT 复制动画轨迹逻辑。

#### Scenario: 喂养与预测共用 Overlay 实现

- **WHEN** 喂养页与预测页均需展示落库飞入
- **THEN** 系统 MUST 复用同一飞入 Overlay（或等价共享组件）
- **AND** MUST 仅通过不同 LandingTarget 区分落点

### Requirement: 仅当前可见页飞入

When History WebSocket/SSE delivers a history mutation, the client MUST attempt the fly animation only if the home PageView current page is feeding or smart prediction. Other pages (including UCG) MUST NOT play the fly animation for that signal. 当 History WS/SSE 推送历史变动时，客户端 MUST 仅在主页 PageView 当前页为喂养或智能预测时尝试飞入；其它页（含 UCG）MUST NOT 播放该次飞入。

#### Scenario: 用户在预测页

- **WHEN** 当前页为智能预测且收到历史变动
- **THEN** 系统 MUST 在预测页尝试飞入（落点为预测卡 logo）

#### Scenario: 用户在喂养页

- **WHEN** 当前页为喂养且收到历史变动
- **THEN** 系统 MUST 在喂养页尝试飞入（落点为历史行 logo）

#### Scenario: 用户在 UCG 页

- **WHEN** 当前页为 UCG 且收到历史变动
- **THEN** 系统 MUST NOT 播放落库飞入动画

### Requirement: 预测落点为对应卡片当前 logo

For a history record mutation while the prediction page is visible, the landing point MUST be the global center of the prediction card logo slot for the record's root prediction row, using whatever EventLogo is currently displayed in that slot (root or leaf timing chrome). If the card is off-screen, the client MUST scroll it into view before measuring. 预测页可见时，落点 MUST 为该 record 对应 root 预测行卡片上**当前展示** logo 槽的全局中心（根图或计时叶子图）；若卡不在屏内，客户端 MUST 先滚入可视再测锚。

#### Scenario: 网格计时中叶子图

- **WHEN** 对应预测卡处于计时中 chrome 且标题旁展示叶子 EventLogo
- **THEN** 飞入落点 MUST 为该当前展示 logo 的中心

#### Scenario: 卡在瀑布流下方

- **WHEN** 对应预测卡初始不在可视区域
- **THEN** 系统 MUST 先自动滚动使该卡 logo 锚点可见
- **AND** 再启动飞入动画

### Requirement: 无可用锚点则不飞入

If prepare/measure cannot obtain a usable on-screen landing anchor for the current page, the client MUST NOT start the fly animation (MUST NOT fake a center-only landing as success feedback). 若当前页无法测得可用屏内落点锚点，客户端 MUST NOT 启动飞入（MUST NOT 以仅中心展示冒充落库反馈）。

#### Scenario: 删除后无历史 logo

- **WHEN** WS 推送删除且喂养页历史行 logo 已不存在
- **THEN** 系统 MUST NOT 播放飞入动画

#### Scenario: 无对应预测卡

- **WHEN** 预测页可见但找不到该 record 对应的预测卡锚点
- **THEN** 系统 MUST NOT 播放飞入动画
