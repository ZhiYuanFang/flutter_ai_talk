## MODIFIED Requirements

### Requirement: Feeding page SHALL bootstrap UCG unread count via HTTP when repo becomes active

The client MUST invoke HTTP unread calibration (`syncUcgUnreadFromServer` or equivalent) when the user is logged in with bound wxId and the **home pager shell** (`UcgHomeShell` or equivalent) activates the UCG home session, without requiring the user to enter UCG Shell first and **without** requiring the feeding `HomeScreen` to mount. The feeding page MUST NOT be the owner of UCG chat WebSocket `setConnectionDesired` activation.

已登录且 wxId 已绑定时，**主壳**激活 UCG 会话后必须主动 HTTP 校准未读（会话 + 互动 OR），不得要求用户先进入 UCG Shell，也 **不得** 依赖喂养页挂载才建连 / 校准。喂养页 **必须 NOT** 再作为 UCG chat desired 的激活所有者。

#### Scenario: 冷启动主壳拉取未读

- **WHEN** 已登录且 wxId 已绑定用户冷启动进入主壳（默认可落在预测页）
- **THEN** 客户端 SHALL 在主壳会话激活路径发起 HTTP 未读校准
- **AND** 服务端存在未读时 `ucgUnreadCountProvider > 0` 且消息 Tab / 广场悬浮球未读指示 SHALL 可反映该计数

#### Scenario: 未绑定 wx 时不请求

- **WHEN** 用户已登录但 wxId 未绑定（`sub` 为 0 或空）
- **THEN** 客户端 SHALL NOT 发起 UCG 未读 HTTP 校准
- **AND** SHALL NOT 显示 UCG 未读红点

#### Scenario: 喂养页不再激活 UCG 传输

- **WHEN** 用户首次挂载喂养 `HomeScreen`
- **THEN** 客户端 MUST NOT 仅因喂养页 mount 调用 `activateUcgHomeSession` / `mountUcgHomeTransportsIfEligible`
- **AND** UCG 会话激活 MUST 已由主壳路径负责（或随后由主壳补齐）

### Requirement: Feeding page SHALL bootstrap UCG unread count via HTTP when UCG WebSocket becomes ready

The client MUST invoke HTTP unread calibration (`syncUcgUnreadFromServer` or equivalent) once per logged-in session when UCG chat WebSocket transitions to ready (`wsReadyStream` false→true after `auth_ok` and handshake pong), without requiring the user to enter UCG Shell first and without requiring feeding page mount. The client MUST NOT rely on `HomeScreen._init()` immediate HTTP fetch as the cold-start baseline. Each session MUST perform at most one such baseline until logout; WebSocket reconnect alone MUST NOT repeat baseline sync.

已登录且 wxId 已绑定时，UCG 聊天 WebSocket 本会话**首次 ready** 后必须 HTTP 校准未读一次作为 baseline；不得依赖喂养页 `_init`。断线重连 alone 不得重复 baseline；登出后重新登录可再走一次。

#### Scenario: 冷启动 WS ready 后拉取历史未读

- **WHEN** 已登录且 wxId 已绑定用户冷启动进入主壳，且 UCG WebSocket 完成握手变为 ready
- **THEN** 客户端 SHALL 发起一次 HTTP 未读 baseline 校准
- **AND** 服务端存在未读时 `ucgUnreadCountProvider > 0`

#### Scenario: WS ready 前不把 Home._init 当 baseline

- **WHEN** UCG WebSocket 尚未 ready
- **THEN** 客户端 SHALL NOT 因喂养 `HomeScreen._init` 单独发起冷启动未读 baseline HTTP

#### Scenario: WS 重连不重复 baseline

- **WHEN** 同一会话内 UCG WebSocket 断线后重连并再次 ready
- **AND** 本会话 baseline 已成功触发过
- **THEN** 客户端 SHALL NOT 再次因 ready 事件发起 baseline HTTP
- **AND** 实时未读仍 SHALL 依赖 WS 乐观 +1 与显式 reconcile（resume/已读/刷新等）

#### Scenario: WS 不可用时不 fallback baseline

- **WHEN** 冷启动后 UCG WebSocket 无法 ready（含 gaveUp）
- **THEN** 客户端 SHALL NOT 因 baseline 失败而额外发起超时或 gaveUp HTTP fallback
- **AND** 未读指示 MAY 在 resume、进入消息 Tab 刷新或其他显式 reconcile 路径后再对齐

#### Scenario: 未绑定 wx 时不请求

- **WHEN** 用户已登录但 wxId 未绑定（`sub` 为 0 或空）
- **THEN** 客户端 SHALL NOT 发起 UCG 未读 HTTP baseline
