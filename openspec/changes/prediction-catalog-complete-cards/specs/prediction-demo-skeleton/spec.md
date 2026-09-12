## MODIFIED Requirements

### Requirement: Cold prediction states SHALL show root-event countdown skeleton

When the smart prediction page is in a cold demo state — user not logged in, or logged in but unbound (no usable deviceNo) — the client SHALL render prediction event rows for **every** catalog root event (`parentId == null`) as a skeleton preview. Each skeleton row MUST expose a countdown whose target time lies within the next three hours from page mount. Skeleton rows MUST NOT be persisted as feeding history and MUST NOT be written as recall seeds. When the user is bound, the client MUST NOT use this demo skeleton solely because prediction-range real history is empty; bound empty history MUST use hot catalog-complete rows as specified by `smart-prediction-page`.

冷态（未登录、或已登录未绑定）下，客户端 **必须** 以目录中全部无父根事件渲染预测骨架行；各行倒计时目标 **必须** 落在进入本页后的未来 3 小时内；骨架 **不得** 写入喂养历史或回忆种子。已绑定时，客户端 **不得** 仅因预测 range 真历史为空而使用本 demo 骨架；已绑定空历史 **必须** 走 `smart-prediction-page` 规定的热态目录完备行。

#### Scenario: 未登录展示全根骨架

- **WHEN** 用户未登录并打开智能预测页
- **THEN** UI MUST 展示覆盖全部无父根事件的骨架预测行
- **AND** 各行倒计时目标 MUST 落在未来 3 小时内

#### Scenario: 未绑定展示全根骨架

- **WHEN** 用户已登录但无可用 deviceNo 并打开智能预测页
- **THEN** UI MUST 展示覆盖全部无父根事件的骨架预测行

#### Scenario: 已绑定无历史不走骨架

- **WHEN** 用户已绑定且预测 range 就绪且真历史为空
- **THEN** 预测主内容区 MUST NOT 仅因此展示 demo 骨架行
- **AND** MUST 展示热态目录完备预测卡

#### Scenario: 骨架不落库

- **WHEN** 冷态骨架正在展示
- **THEN** 客户端 MUST NOT 因骨架生成而向 history 仓库写入记录
- **AND** MUST NOT 将骨架行写入回忆种子存储
