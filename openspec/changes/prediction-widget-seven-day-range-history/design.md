## Context

喂养列表、小组件 30 日预拉、预测页 7 日预拉曾共用 `homeHistoryProvider` 分页，导致刷新截断深度、预拉与 UI loadMore 抢 in-flight、FutureProvider 一次缓存后不再加深。兄弟仓 `go_ai_talk` 已暴露：

- `GET /device/history/api/filter`：`deviceNo`、`eventIds`（空=全事件）、`startTime`/`endTime`（Unix 秒）、`limit`（默认 100，上限 500）
- `GET /device/history/api/v2/list`：分页 + 可选时间窗 + `limit`

产品：预测与小组件只需近 7 日；与喂养分页隔离。

## Goals / Non-Goals

**Goals:**

- 独立 range store + 上述接口拉取本地 `[today-6d 00:00, now]`（与折线窗一致）。
- 预测页 / 顶栏贴士 / 小组件预测共用该 store；废止 30 日分页预拉与预测页 `loadNext` 拼 7 日。
- 副作用 HTTP：single-flight、失败熔断、非 provider 构造无防护启动；日志走 `AppDebugLog.homeWidget`（或既有 tag，不新增除非必要）。

**Non-Goals:**

- 不改 `event_next_predictor` 算法公式。
- 不改喂养列表 UX / v1 `list` 契约。
- 不在 Go 仓新开 path；不新建 `**/test/**`。
- 不解决 `scheduleHomeWidgetSync` self-ref 断言（可另 change；本 change 拉取路径避免在 homeHistory 更新栈内读自身即可）。

## Decisions

1. **时间窗**  
   本地日历：`start = DateTime(now.y, now.m, now.d) - 6d` 的 00:00，`end = now`（或当日 23:59:59 若实现更简，但 MUST 覆盖「此刻」之前的记录）。与折线 `[now-6d, now]` 对齐。

2. **接口策略**  
   - 首选 `filter`：`eventIds` 空，`limit=500`，带 `startTime`/`endTime`。  
   - 若返回条数 == 500：再用 `v2/list` 同窗分页补全直至无更多或熔断。  
   - 备选：全程 `v2/list` 分页；实现选成本更低者，行为以满足「窗内尽量完整」为准。

3. **独立 provider**  
   例如 `predictionRangeHistoryProvider`（AsyncNotifier / 等价）：持有 `List<HistoryRecord>` + loading/error；**禁止** merge 进 `HomeHistoryNotifier.items`。  
   消费方：`smartPredictionRowsProvider`、顶栏 tip、`syncHomeWidgetFromRef` 内 `predictAllUpcoming` 的 history 参数。

4. **触发与失效**  
   - 进预测页 / 小组件 sync 需要预测时：ensure range（single-flight）。  
   - 喂养历史 create/update/delete（含 WS 反映到本地后）：invalidate range 并 single-flight refetch（可 debounce 短窗）。  
   - 登出清空。  
   - `widgetHistoryDepthReady`：成功拉完 7 日窗后置 true；或改为「range ready」语义并更新读写点；失败/熔断后仍允许用已有 range 缓存出非 loading 小组件。

5. **废止路径**  
   - `ensureWidgetHistoryDepth` 的 30 日 `loadNext` 循环删除或改为委托 range ensure。  
   - `ensurePredictionHistoryDepth` / `predictionHistoryDepthProvider` 改为 watch/ensure range store；图区 loading = range loading。

6. **与喂养隔离**  
   Range HTTP **不得** 改变 `highestPageLoaded` / 截断喂养 items。喂养下拉 refresh/loadMore 行为保持独立。

## Risks / Trade-offs

- **[Risk] filter 500 截断** → Mitigation：命中上限走 v2 分页；日志记录 `truncated`/`page`。  
- **[Risk] 双份内存** → Mitigation：仅 7 日窗，体量可控；不持久化强制（MAY 会话内缓存）。  
- **[Risk] 预测与喂养列表短暂不一致** → Mitigation：产品接受；WS 后 refetch range。  
- **[Trade-off] 算法不再看到 7 日前样本** → 产品明确接受；与折线窗一致。

## Migration Plan

1. 封装 filter / v2 list 客户端。  
2. 上线 range store；切换预测页、顶栏、小组件消费。  
3. 拆除 30 日 / 预测分页预拉。  
4. 手工：进预测页见 loading→折线；喂养顶拉加深列表不影响/不阻塞；小组件有预测；log 见 filter 或 v2/list。

回滚：恢复 `ensureWidgetHistoryDepth` 30 日与预测页 homeHistory 预拉（旧代码路径）。

## Open Questions

- 无阻塞项（接口与 7 日窗已确认）。
