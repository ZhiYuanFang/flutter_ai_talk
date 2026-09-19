## Context

喂养记录分析与成长轨迹详情页在生成时走 SSE 思考流。分析状态挂在全局 Riverpod notifier 上，退出页面不会取消请求。

喂养页再进时 `FeedingAnalysisScreen.initState` 调用 `hydrateLatestOnly()`，该方法用 `force=false` 的 latest **整份替换**状态，并把 `loading` 写成 `false`。于是正文变成历史列表、按钮重新可点。此时 `refreshDailyManual` 发现 `_inFlight` 仍在，直接返回同一次 Future，不再发请求，也不把 `loading` 设回 `true`。第一次尚未结束时返回值为空，页面没有 Toast。用户看到的就是「历史记录 + 再点没反应」。

成长轨迹的 `ensureLatest` 在 `streaming` / `asking` 时会直接返回，不会用历史结果盖掉进行中会话。本次不改这条路径。

Go 在 Redis 锁未抢到时已返回「护理留意生成进行中，请稍候」，但上述复现里第二次点击没有出客户端，改接口文案解决不了。

## Goals / Non-Goals

**Goals:**

- 思考进行中，两个详情页都有一句固定说明：正在为宝宝针对性分析，会比较久，可以先去做别的，回来再看。
- 喂养分析未结束时再进页，仍显示思考区与该说明，而不是历史列表。
- 喂养分析未结束时再点「AI智能分析」，立刻 Toast，且不发起第二次生成。

**Non-Goals:**

- 成长轨迹 `MemorySaver` 断点释放、TTL、`delete_thread`。
- 改 Go / Python 锁、错误码或 SSE 包解析。
- 杀进程或断网后仍保证本次分析跑完（连接断开后本次可能被取消；文案只承诺同一次 App 进程内离开页面再回来）。
- 成长轨迹提问阶段展示「可以先离开」——该阶段必须留在页上作答。
- 新建 `**/test/**`。

## Decisions

### 1. 提示放在 `AiThinkingPane` 之外

思考正文会随 SSE 增量与 `\r` 阶段清除被改写。等待说明放在思考区上方，不写入 `thinking` 字符串，也不在 feature 内另做跟滚。

裸 13 号功能色文字会和思考流看成同一段。改为共享 `AnalysisWaitCallout`：`AppColor.fieldFill` 底、左侧功能色条、时钟图标；标题加粗「正在为宝宝分析，会比较久」，次行「可以先去做别的，过一会儿回来看结果。」字色仍用功能色加深，不新增色值。

- 喂养：`careState.loading == true` 时与思考区一起出现。
- 成长：仅 `showThinking` 或 `phase == streaming` 时出现；`asking` 不出现。

备选：写进常驻 blurb。否决——喂养已有「近两日记录」说明，常驻会和「正在分析」混在一起；用户要的是进行中的预期。

### 2. 进行中的判定以 `_inFlight` 为准，而不是 `loading`

`loading` 会被 `hydrateLatestOnly` 清掉，不能当锁。`_inFlight != null` 才表示上一次 `analyzeStream` 还没结束。

`hydrateLatestOnly` 在 `_inFlight != null` 时直接返回，不替换 `items` / `loading` / `thinking`。没有进行中分析时，进页拉 latest 的行为不变。

备选：hydrate 只合并用量、保留列表。否决——进行中应以思考区为准，历史列表会让用户以为可以再开一轮。

### 3. 重复点击立刻返回文案，不等待上一次 Future

现在的 `refreshDailyManual` 在 `_inFlight != null` 时 `return _inFlight`，调用方会一直等到第一次结束；成功时错误为空，Toast 不出现。

改为：`_inFlight != null` 时立刻 `return Future.value('上一次分析还在进行，请稍后再试')`，不 `await` 旧 Future，不进入 `_refreshManualImpl`。

页面上该按钮在 `loading` 时也必须仍可点，把返回文案交给现有 `showApiToast`。若 `onTap` 仍为 `null`，用户点不到，故障还在。

备选：按钮保持禁用，只靠思考区说明。否决——用户明确要解决「再点无效」；禁用点击没有反馈。

### 4. 不改服务端

本复现的第二次点击被客户端单飞吃掉。Go 已有进行中文案，但到不了这条路径。进程被杀、锁仍在时的 envelope 解析留待以后，不塞进本次。

## Risks / Trade-offs

- [文案承诺「回来看结果」，但杀进程后 SSE 会断] → 文案只覆盖留在 App 内离开页面；不写「关掉也行」。结果仍靠现有落库：同进程内请求继续，完成后写入 latest。
- [进行中跳过 hydrate，用量数字可能略旧] → 可接受；结果事件会带回 `usedToday` / `dailyLimit`。
- [重复点击 Toast 与第一次最终失败的 Toast 可能叠在一起] → 重复点击的文案立即出现；第一次结束时的失败 Toast 仍由当时仍挂载的页面处理。离开后再进不会补弹第一次的失败（现有行为，不扩大）。

## Migration Plan

仅客户端。发版即生效，无数据迁移。回滚即去掉提示与 `_inFlight` 早退。

## Open Questions

无。文案与「提问阶段不展示」已在探索中定下。
