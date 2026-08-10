## ADDED Requirements

### Requirement: Cold prediction states SHALL show root-event countdown skeleton

When the smart prediction page is in a cold demo state — user not logged in, or logged in but unbound (no usable deviceNo), or bound with prediction-range real history ready and empty — the client SHALL render prediction event rows for **every** catalog root event (`parentId == null`) as a skeleton preview. Each skeleton row MUST expose a countdown whose target time lies within the next three hours from page mount. Skeleton rows MUST NOT be persisted as feeding history and MUST NOT be written as recall seeds.

冷态（未登录、未绑定、或已绑定且 range 真历史就绪为空）下，客户端 **必须** 以目录中全部无父根事件渲染预测骨架行；各行倒计时目标 **必须** 落在进入本页后的未来 3 小时内；骨架 **不得** 写入喂养历史或回忆种子。

#### Scenario: 未登录展示全根骨架

- **WHEN** 用户未登录并打开智能预测页
- **THEN** UI MUST 展示覆盖全部无父根事件的骨架预测行
- **AND** 各行倒计时目标 MUST 落在未来 3 小时内

#### Scenario: 未绑定展示全根骨架

- **WHEN** 用户已登录但无可用 deviceNo 并打开智能预测页
- **THEN** UI MUST 展示覆盖全部无父根事件的骨架预测行

#### Scenario: 已绑定无历史底层为骨架

- **WHEN** 用户已绑定且预测 range 就绪且真历史为空
- **THEN** 预测主内容区 MUST 展示骨架行（量身定做若出现则以 Dialog 叠加其上）

#### Scenario: 骨架不落库

- **WHEN** 冷态骨架正在展示
- **THEN** 客户端 MUST NOT 因骨架生成而向 history 仓库写入记录
- **AND** MUST NOT 将骨架行写入回忆种子存储

### Requirement: Skeleton countdown offsets SHALL be stable within a page mount

Within a single mount of the smart prediction page, each skeleton root’s countdown target offset MUST remain fixed across second-tick UI refreshes and incidental rebuilds. The client MUST reshuffle those offsets only when the smart prediction page is fully remounted (leave and re-enter, or equivalent State recreation).

同一预测页 mount 内，各骨架根的倒计时偏移在秒级刷新与偶然 rebuild 时 **必须** 保持固定；**仅**在预测页整页 remount 时 **必须** 重抽偏移。

#### Scenario: 秒 tick 不重抽

- **WHEN** 冷态骨架已展示且仅发生秒级倒计时刷新或同页 rebuild
- **THEN** 各根骨架的 nextAt（相对 mount 的偏移）MUST 保持不变

#### Scenario: 整页重建重抽

- **WHEN** 用户离开智能预测页后再进入导致页面 remount
- **THEN** 客户端 MUST 重新抽取各根骨架倒计时偏移（仍落在未来 3 小时内）
