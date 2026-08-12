## ADDED Requirements

### Requirement: 预测页 MUST 由壳层唯一 Overlay 承接飞入请求

When the smart prediction page is the home PageView current page and `historyEventFlyRequestProvider` emits a request with `targetPage` equal to prediction, the home shell KeepAlive wrapper for prediction MUST mount the shared history fly Overlay (same implementation as feeding) with a `PredictionCardFlyLanding` resolved from the request `rootEventId` logo anchor. The smart prediction screen content MUST NOT mount a second fly Overlay for the same request. If animations are disabled or no usable logo anchor exists after prepare/measure, the client MUST NOT play a fake center-only animation and MUST clear or complete the fly session. 当智能预测为当前主页且飞入请求的 `targetPage` 为预测时，主页壳层预测 KeepAlive MUST 挂载与喂养共用的历史飞入 Overlay，落点为请求 `rootEventId` 对应预测卡 logo；预测页内容 MUST NOT 再挂第二层飞入 Overlay。若系统关闭动画或 prepare/measure 后无可用锚点，MUST NOT 以仅中心动画冒充，并 MUST 结束该次飞入 session。

#### Scenario: 预测页收到飞入请求仅播一次

- **WHEN** 当前页为智能预测且发出 `targetPage=prediction` 的飞入请求
- **AND** 对应 root 预测卡 logo 锚点可测得
- **THEN** 系统 MUST 播放共享飞入动画恰好一次并落向该 logo

#### Scenario: 无锚点不飞

- **WHEN** 预测页收到飞入请求但找不到可用 logo 锚点
- **THEN** 系统 MUST NOT 播放飞入动画
