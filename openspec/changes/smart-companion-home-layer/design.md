## Context

- 现网 `/home` 由 `UcgHomeShell` 承载 **2 页** PageView：`0=喂养 HomeScreen`，`1=UCG`（懒挂载 + 右缘「进入广场」拉条）。
- 「胖宝诊疗」为独立路由 `/pangbao`（`PangbaoAiScreen`），自管 `ClinicWsClient`；文案/免责/额度为诊疗气质；本地 `PangbaoClinicSessionStore` 按 `deviceNo` 持久化；`session_sync` 非空时以服务端 turns 重建列表（本地更长前缀会丢）。
- 喂养动作已可触发 tip SSE → `HomeTipPanel`，但尚无进陪伴闭环。
- 约束：Clinic WS **必须**经 `ResilientWebSocketClient`；provider 创建不得自动副作用建连；OpenSpec 基线 v2.0.3；制品中文 + Requirement 含 SHALL/MUST。

## Goals / Non-Goals

**Goals:**

- 主页三页：`[陪伴 | 喂养默认 | UCG]`，进入体验对齐广场（懒挂载 + 边缘拉条）。
- 诊疗 UI/文案演进为智能陪伴（真玻璃可爱风 + 非医疗弱提示）。
- tip「接着聊」：done 整卡/右滑注入一次并消费；A3 跳过「我来啦」。
- 「我来啦」仅当天首次（且无 tip 注入时）。
- 本地会话长存；陪伴页右上角玻璃确认清记录；不动全局清缓存。
- `session_sync` 截断时保留本地更早轮次 + **纯线无字**分隔。
- Clinic WS：滑走保持；进页检查建连。
- 客户端先行去掉 voiceAi / clinicAi / polish 额度 UI 与 40302 限制路径。

**Non-Goals:**

- 不改 Clinic WS 帧协议与 tip SSE 协议。
- 不在本 change 改 go 后端额度/会话 TTL（客户端先行）。
- 不改设置中心/账号切换的 `feedRepository.clearCache()` 语义。
- 不把真玻璃推广到 UCG Feed 长列表。
- 不新建 `**/test/**` 测试文件（除非用户另行要求）。

## Decisions

### 1. PageView 索引与默认页

- **决策**：`itemCount=3`；`initialPage=1`（喂养）；page0=陪伴，page2=UCG。所有原 `0/1` 硬编码（返回键、广场再点回喂养、拉条显隐、dock 禁滑）改为常量或语义命名（`kFeedingPage` 等）。
- **理由**：满足「-1 层」+ 默认仍落喂养；右滑进陪伴、左滑进广场。
- **备选**：逻辑 -1 + 变换控制器——拒绝，Flutter `PageController` 用非负 index 更简单。

### 2. 陪伴懒挂载镜像 UCG

- **决策**：`_companionEverMounted` / `_ucgEverMounted` 各自独立；冷启动不 build 陪伴页、不建 Clinic WS。
- **理由**：与 v2.0.3 UCG 懒挂载一致，避免冷启动成本与同意/绑宝前置。

### 3. Clinic WS 所有权上移

- **决策**：在 home/companion session 激活路径持有 `ClinicWsClient`（或等价 provider），`connectionDesired` 在「陪伴曾挂载且用户仍登录/绑宝」期间保持 true；陪伴页只订阅 phase/帧。滑到喂养/UCG **不断开**；进入陪伴时若未 ready 则 ensure connect。
- **理由**：满足「滑走保持」；避免 Screen dispose 拆连。
- **备选**：每进页新建 client——拒绝，与保持连接冲突。
- **约束**：遵守副作用 HTTP/WS 治理；不得在无关 provider `build` 里自动 connect。

### 4. tip 注入模型

- **决策**：本地会话支持 `source=tip` 的助手气泡（可无 user question）；注入条件：`TipDisplayState.done`、未消费、文本非空（优先 `answer`）。注入后标记消费；**不**自动发下一句用户话。清理陪伴记录 **不**强制 dismiss 首页 tip（若 tip 仍展示且未消费标记因清理重置——默认：**清记录重置消费标记**，以便同一 tip 可再次注入；若 tip 已关闭则无注入）。
- **理由**：「接着聊贴士」+「注入一次」；清记录后允许重新带入仍展示的 tip 更符合预期。
- **服务端上下文**：首版以本地展示为主；后续用户消息走既有 Clinic question（服务端不一定含 tip）。若需强上下文，可在 design 实现时将 tip 摘要拼进下一句——**默认不拼**，避免污染用户可见输入；依赖「接着聊」自然语言。

### 5. 「我来啦」门闩

- **决策**：本地按日历日（设备本地时区）记录 `lastGreetingDate`；进入陪伴且完成 hydrate/注入判定后：无 tip 注入且日期 ≠ 今日 → 发送 question=`我来啦` 并写日期。有 tip 注入 → 跳过且**不**写日期（当天稍后无 tip 再进仍可问候）——**修正为产品 A3：有 tip 跳过发送**；是否占用「当天首次」：**占用**（写入今日已问候），避免同日 tip 后又弹问候打扰。  
  **冻结**：有 tip 注入时跳过「我来啦」，并标记当日已问候（避免同日二次问候）。
- **理由**：陪伴感优先于机械问候堆叠。

### 6. session_sync 截断横线

- **决策**：非空 `session_sync` merge 时：
  1. 匹配 question 的轮次以服务端 Q/A 权威，保留本地 thinking；
  2. 本地 completed 中 question **不在**服务端 turns 的，保留在列表**上方**；
  3. 若存在至少一条此类「仅本地」轮次，则在仅本地块与服务端块之间插入 **纯线无字** 分隔 item（可持久化标记，清理时删除）；
  4. 本地 failed 仍按现网规则追加（不在服务端成功集中的）。
  空 turns：保持现网「不清空」。
- **理由**：长存本地与服务端短窗口共存，用户可见截断而非静默丢失。

### 7. 清记录 UI

- **决策**：陪伴顶栏右上角清理图标 → `showGlassDialog`（或统一玻璃确认）二次确认 → 清空内存列表 + `PangbaoClinicSessionStore` 该 device 快照 + 截断线状态；**不**调用 `feedRepository.clearCache()`。
- **理由**：用户明确要求；与全局清缓存解耦。

### 8. 真玻璃视觉

- **决策**：陪伴页壳层/气泡/输入区使用真 `BackdropFilter` 玻璃（可复用/延伸 `HistoryEditGlassPanel` 或 UCG compose 真玻璃 token），可爱圆角与柔和 tint；单页成本可接受。
- **备选**：假玻璃——拒绝，产品指定真玻璃。

### 9. 额度客户端先行

- **决策**：移除/停用 `AiQuotaRemainingHint` 在 voiceAi、clinicAi、polish 的展示；`handleAiQuotaBusinessCode` 对 **40302** 不再弹「额度用完」（可映射为通用错误或忽略弹框，inline 用通用文案）；**40301** 仍引导登录。停止因额度 invalidate 刷新 hint 的必要 UI。后端仍可能返回 40302——客户端按无限额体验降级为轻量错误，不引导充值/等待下月。
- **理由**：产品「客户端先行」。

### 10. 路由 `/pangbao`

- **决策**：主入口改为 PageView page0；顶栏入口删除。`/pangbao`：**重定向到 `/home` 并 animateTo 陪伴页**（或废弃 push），避免旧深链进独立诊疗页双实例。
- **理由**：单一陪伴状态与单一 WS 所有者。

## Risks / Trade-offs

- **[Risk] 三页索引漏改导致返回键/拉条错乱** → 集中常量 + 全库搜 `animateToPage(0|1)` / `_pageIndex ==`；手工验收矩阵。
- **[Risk] WS 上移引发未登录/未绑宝仍建连** → desired 条件与现诊疗屏一致（同意 + 登录 + deviceNo）；懒挂载前不 connect。
- **[Risk] tip 注入无服务端上下文，模型「接不上」** → 接受首版本地接聊；后续可加 seed API。
- **[Risk] 后端仍限额度，用户见泛化错误** → proposal 已声明后端另 change；错误文案避免再提「额度」。
- **[Risk] 本地历史无限增长** → 右上角清理；后续可加条数上限（本 change 不做）。
- **[Risk] 真玻璃低端机掉帧** → 仅陪伴单页；必要时降低 blur sigma（实现期可调）。

## Migration Plan

1. 落地壳层三页与拉条，默认 page=1，旧双页行为由喂养↔UCG 索引平移验证。
2. 嵌入陪伴页 + WS 上移；验证滑走保持与进页建连。
3. tip 桥接与「我来啦」门闩。
4. session_sync 横线 + 清记录弹窗。
5. 去额度 UI/40302 路径。
6. `/pangbao` 深链重定向。
7. 回滚：恢复双页壳与 `/pangbao` 独立屏（git revert）；本地 store key 可兼容读写。

## Open Questions

- 无（探索阶段已冻结）。实现期若发现 tip 消费与面板 dismiss 竞态，在 tasks 中补一条对齐即可。
