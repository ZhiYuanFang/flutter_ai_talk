## ADDED Requirements

### Requirement: Companion conversation SHALL persist locally without 12-hour expiry

The client MUST persist companion conversation turns (completed, failed, tip-sourced, and truncation dividers) locally scoped by `deviceNo`, and MUST NOT apply a 12-hour automatic purge of that local store. Empty-state copy MUST NOT claim that Q&A is kept only for 12 hours. 客户端 **必须** 按 `deviceNo` 持久化陪伴会话且 **不得** 对本地陪伴记录做 12 小时自动清理；空态文案 **不得** 声称仅保留 12 小时。

#### Scenario: 重启后仍可见本地历史

- **WHEN** 用户曾产生陪伴对话并杀进程后再次进入陪伴页且已绑定同一 `deviceNo`
- **THEN** 客户端 MUST 从本地 store hydrate 并展示历史
- **AND** MUST NOT 仅因超过 12 小时而丢弃本地记录

#### Scenario: 空态无 12 小时文案

- **WHEN** 陪伴会话为空并展示空态
- **THEN** 文案 MUST NOT 包含「仅保留12个小时」或等价表述

### Requirement: Clinic WebSocket SHALL stay connected after leaving companion page

Once the companion page has been mounted in the home PageView and connection is desired (consent + login + device bound), the client MUST keep Clinic WebSocket `connectionDesired` true while the user remains in the `/home` shell, including when the PageView shows feeding or UCG pages. Entering the companion page MUST check readiness and connect if not ready. 陪伴页挂载且具备建连条件后，用户仍在 `/home` 壳内（含喂养/UCG）时 Clinic WS **必须** 保持 desired；进入陪伴页 **必须** 检查并在未就绪时建连。

#### Scenario: 滑回喂养不断开

- **WHEN** 用户已在陪伴页完成建连后右滑/切回喂养页
- **THEN** Clinic WS MUST NOT 仅因离开陪伴页而将 `connectionDesired` 置 false

#### Scenario: 再进陪伴检查建连

- **WHEN** 用户从喂养进入陪伴页且 Clinic WS 未 ready
- **THEN** 客户端 MUST 发起/恢复建连

#### Scenario: 冷启动未进过陪伴不建连

- **WHEN** 用户冷启动停留喂养页且从未进入过陪伴页
- **THEN** 客户端 MUST NOT 仅因进入 `/home` 而挂载并连接 Clinic WS

### Requirement: Daily first entry MAY auto-send greeting「我来啦」

When the user enters the companion page, if it is the first companion entry of the local calendar day and no tip injection occurs on that entry, the client MUST automatically send a Clinic question with text「我来啦」after consent and connection allow sending. If tip injection occurs on that entry, the client MUST NOT send「我来啦」and MUST mark the day as greeted. 进入陪伴页时：当天首次且无 tip 注入则 **必须** 自动发送「我来啦」；若本轮注入 tip 则 **不得** 发送「我来啦」且 **必须** 标记当日已问候。

#### Scenario: 当天首次无 tip 问候

- **WHEN** 用户在本地日历日首次进入陪伴页，无可注入 tip，且已同意并具备发问条件
- **THEN** 客户端 MUST 发送 question「我来啦」

#### Scenario: 有 tip 注入跳过问候

- **WHEN** 进入陪伴页时注入了一条 tip 会话内容
- **THEN** 客户端 MUST NOT 发送「我来啦」
- **AND** 同日再次进入（无新 tip）MUST NOT 再发送「我来啦」

#### Scenario: 同日第二次不重复问候

- **WHEN** 用户同日再次进入陪伴页且当日已问候或已因 tip 标记问候
- **THEN** 客户端 MUST NOT 再次自动发送「我来啦」

### Requirement: Tip content SHALL inject once as companion conversation context

When entering companion with an unconsumed tip in `done` state and non-empty display text, the client MUST append that tip text as a new companion conversation item (tip-sourced assistant content), mark the tip consumed, and MUST NOT auto-send an additional user question for that injection. 进入陪伴时若存在未消费且 `done` 的 tip，**必须** 将其文本注入为陪伴会话内容并标记已消费，**不得** 因此再自动发送用户 question。

#### Scenario: 注入并消费

- **WHEN** tip 为 done、未消费，用户进入陪伴页（点卡或横滑）
- **THEN** 对话列表 MUST 新增 tip 文本对应的会话内容
- **AND** 该 tip MUST 标记为已消费

#### Scenario: 再次进入不重复注入

- **WHEN** 同一 tip 已消费后用户再次进入陪伴页且无新 tip
- **THEN** 客户端 MUST NOT 再次注入同一 tip 文本

### Requirement: session_sync truncation SHALL keep local-only history above a plain divider

When a non-empty `session_sync` arrives and local completed turns include questions absent from the server `turns`, the client MUST retain those local-only turns above the server-authoritative turns, and MUST insert a plain horizontal divider item (line only, no caption text) between the two blocks. Empty `session_sync` MUST NOT clear existing local/in-memory history. 非空 `session_sync` 若截断本地更早轮次，**必须** 保留仅本地轮次于上方，并以**纯线无字**横线分隔；空 sync **不得** 清空本地历史。

#### Scenario: 截断显示纯横线

- **WHEN** 本地有 completed 轮次 Q_old 不在本次 `session_sync.turns` 中，且 sync 含较新轮次
- **THEN** 列表 MUST 先展示 Q_old 等仅本地轮次
- **AND** MUST 插入无文字的长横线分隔项
- **AND** 其下 MUST 展示服务端权威轮次（thinking 合并规则延续）

#### Scenario: 空 sync 不清空

- **WHEN** `session_sync.turns` 为空且内存已有陪伴历史
- **THEN** 客户端 MUST NOT 清空该历史

### Requirement: Client SHALL NOT enforce companion AI quota limits

For companion/Clinic flows, the client MUST NOT block sending or show quota-exhausted dialogs for business code 40302. Login guidance for 40301 MAY remain. 陪伴/Clinic 路径客户端 **不得** 因 40302 拦截发问或弹出额度用尽框；40301 登录引导 MAY 保留。

#### Scenario: 40302 不弹额度框

- **WHEN** Clinic WS 返回 `code == 40302`
- **THEN** 客户端 MUST NOT 弹出「本月额度已用完」类 Glass 弹框
- **AND** MAY 以通用错误 inline 展示（文案 MUST NOT 引导「额度/下月再试」作为唯一产品语义）
