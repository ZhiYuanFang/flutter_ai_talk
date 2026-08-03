## ADDED Requirements

### Requirement: Button-mode feed mutations MUST NOT require History WS ready

While the home input channel is buttons (event grid), the client MUST NOT block event add, stop-timer, or other button-path history HTTP mutations solely because History WebSocket is not ready. The client SHOULD still attempt to keep History WS connected for multi-device sync. 首页输入为**按钮模式**时，客户端 **不得** 仅因 History WS 未就绪而拦截按钮路径的添加、停表等历史 HTTP 变更；客户端 **应** 仍尽力维持 History WS 以同步他端操作。

#### Scenario: 按钮添加不查 WS 门闩

- **WHEN** 用户处于按钮输入模式且 History WS 未就绪
- **AND** 用户触发合法的事件添加
- **THEN** 客户端 MUST 仍发起 add HTTP（受登录/绑宝与网络约束）
- **AND** MUST NOT 仅因 WS 未就绪而 Toast「历史实时连接未就绪…」并中止添加

### Requirement: Voice-mode send MUST keep History WS ready gate

While the home input channel is voice, starting a hold-to-talk session that will send a command, or submitting voice-derived chat text, MUST continue to invoke the existing History WS ready check (`_ensureHistoryWsForSend` or equivalent) and MUST abort the send path with the existing user-visible error when not ready. Switching into voice channel MUST NOT by itself block or toast solely for History WS unreadiness. 语音输入模式下，按住说话开录/发送及语音衍生聊天提交 **必须** 继续使用既有 History WS 就绪门闩；未就绪时 **必须** 按现网文案中止发送。**切换到**语音通道本身 **不得** 仅因 WS 未就绪而拦截切换或单独 Toast。

#### Scenario: 切换语音不拦

- **WHEN** 用户从按钮模式切换到语音模式且 History WS 未就绪
- **THEN** 客户端 MUST 允许进入语音 UI
- **AND** MUST NOT 仅因切换而强制展示「历史实时连接未就绪」Toast

#### Scenario: 语音按住/发送仍门闩

- **WHEN** 用户处于语音模式且 History WS 未就绪
- **AND** 用户按住开录或松手发送聊天
- **THEN** 客户端 MUST 中止该发送路径并展示既有未就绪错误提示
