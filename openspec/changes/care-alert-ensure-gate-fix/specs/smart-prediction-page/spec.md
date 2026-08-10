## ADDED Requirements

### Requirement: Prediction care-alert strip SHALL recover from never-fetched idle

On the smart prediction page, the care-alert card MUST not remain indefinitely on「加载中…」when no care-alert fetch is in flight. After the fetch gate becomes allowed, the page’s host MUST ensure daily load is attempted; if the card is idle-not-ready, the user MUST be able to force refresh via the empty-family refresh control.

智能预测页留意条在无进行中的拉取时 **不得** 无限「加载中…」；门闸放行后宿主 **必须** 尝试 ensure；若处于未就绪空闲，用户 **必须** 能经空态族刷新 force 重试。

#### Scenario: 冷启动后出现 daily 请求或可刷新空态

- **WHEN** 用户冷启动进入预测主页且七日 range 已成功返回非空列表
- **THEN** 在合理时间内客户端 MUST 发起 care-alert daily，或卡片 MUST 进入可刷新空态族（不得永久仅「加载中…」）
