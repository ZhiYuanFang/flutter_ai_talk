## Why

桌面小组件日更提示目前只推原生桌面，进智能陪伴时不会进入本机聊天记录；用户在桌面看到的「注意什么」与陪伴树洞脱节。需要在**不改拉取接口**的前提下，让当日小组件 tip 在进入陪伴时像首页 tip 一样写入本地历史。

## What Changes

- 进入智能陪伴时（既有 `_onCompanionEntryActions` 路径）：若当日有未注入的小组件 tip 文案，追加一条 `isTipSource` 助手气泡并持久化到本机会话 store。
- 注入时机采用 **B3（进陪伴再写）**，禁止在 `syncHomeWidgetFromRef` 成功时直接改会话 store（避免与 `_items` 权威冲突）。
- 与首页 tip 优先级：同次进入若首页 tip 可注入，**只注首页 tip**；小组件 tip 留待后续进入（当日仍未注入则再注）。
- 注入成功后占用当日「我来啦」问候（与首页 tip 一致）。
- 幂等：按本地自然日 `dayKey` 持久化「已注入」；清理陪伴记录**不**复位该日标记（一天最多自动出现一次）。
- 陪伴展示用**未截断**全文；桌面小组件展示仍可 trim（现有 5 行 / 160 字）。
- 拉取接口不变：仍为 `POST /device/history/api/chat`（`fetchWidgetFeedingTip`），不改为 `/device/tip/generate`。

## Capabilities

### New Capabilities

- `widget-tip-companion-bridge`：小组件 tip 缓存、进陪伴注入、与首页 tip /「我来啦」的优先级与幂等。

### Modified Capabilities

- （无）首页 tip 注入规则不改；仅在陪伴入口动作中增加并行分支。

## Impact

- 代码：`widget_tip_cache.dart`（全文 + injected day）、`pangbao_ai_screen.dart`（`_onCompanionEntryActions`）、必要时 `home_widget_sync.dart` 仅透传/不写 store。
- 本地 prefs 键扩展；`PangbaoClinicEntryKind.tip` / `isTipSource` 复用。
- 不改 Android/iOS 原生小组件 UI 契约字段语义（仍推 tip 文本）；不改 tip SSE、Clinic WS、不新建测试文件。
