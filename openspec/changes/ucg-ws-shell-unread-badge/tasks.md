## 1. 主壳激活 UCG 会话

- [x] 1.1 在 `UcgHomeShell` 登录门闸完成后调用 `activateUcgHomeSession`（与历史 WS 激活同级，注意错峰）
- [x] 1.2 从 `HomeScreen` 移除 `mountUcgHomeTransportsIfEligible` / 喂养页 UCG 建连职责
- [x] 1.3 确认 `deactivateUcgHomeSession` 仍仅在主壳 release / 登出路径；离开 UCG 子页不断连

## 2. 未读 HTTP 权威与单飞补跑

- [x] 2.1 为 `syncUcgUnreadFromServer` 增加 in-flight 期间脏标记；结束后若脏则再跑一轮
- [x] 2.2 消息 Tab 下拉刷新与进入消息 Tab 必须触发并写入 `ucgUnreadCountProvider`（会话 active 时）
- [x] 2.3 聊天 `markConversationRead` 成功后每次均可 HTTP 覆盖（去掉或放宽 `_unreadBadgeCleared` 只清一次）
- [x] 2.4 互动收件箱已读路径保持 / 核对仍走 `ucgUnreadSyncProvider`
- [x] 2.5 失败路径用 `AppDebugLog.ucgUnread` 记录，禁止静默吞错
- [x] 2.6 消息列表可见未读覆盖全局角标（`applyUcgUnreadFromVisibleList`）；列表无未读则角标必灭
- [x] 2.7 下拉刷新在 HTTP sync 之后再次以可见列表写入，保证列表优先

## 3. 消息 Tab 连接态横条

- [x] 3.1 订阅 `chatWsPhase`（或 phaseStream），按 design 映射连接中 / 失败 / ready
- [x] 3.2 在消息列表上方展示横条；gaveUp 点击调用 `reconnectChatWebSocket(resetStrike: true)`
- [x] 3.3 未登录 / 无 wxId / 会话未激活时不展示失败横条
- [x] 3.4 **不**改 `ResilientWebSocketClient` 重试参数与 SilentHeal

## 4. 固定红未读点

- [x] 4.1 在 `AppColor` 增加未读点语义色（如 `unreadDot`，固定红）
- [x] 4.2 `UcgBottomDock` 消息红点改用该语义色
- [x] 4.3 `UcgSquareEdgeDock` 未读点改用该语义色

## 5. 验收

- [x] 5.1 冷启落预测页：UCG 会话可激活；有未读时悬浮球/进广场后消息 Tab 红点正确
- [x] 5.2 私信读完或下拉刷新后服务端无未读：三处角标（Tab / 球 / 桌面）清除
- [x] 5.3 断网或 gaveUp：消息 Tab 见失败横条，点重连可恢复；连接中态可见
- [x] 5.4 换主题后红点仍为固定红
- [x] 5.5 对照 `openspec/project.md`：无裸 print；无新建 test；未改 Android 原生则无需 release APK
