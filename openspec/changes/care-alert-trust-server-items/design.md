## Context

喂养工作台经 SSE `analyzeStream` 收思考与 `result` 后，把 `items`/`day` 写入 `PredictionCareAlertState`；UI 却 watch 派生 provider `predictionCareAlertProvider`，其中用 `careAlertShanghaiDayKey()` 与 `st.dayKey` 比较，不等则返回 `[]`。现网服务端 `day` 为带时分字符串（日志见 `day=2026-09-17 14:03`），与客户端 `YYYY-MM-DD` 永不等，导致「思考清空、列表空、重进 hydrate 才有数据」。hydrate 路径本就用本地日键覆盖，掩盖了同一过滤对 GET 的影响。产品已确认：不需要本地按日过滤，展示只依赖服务端返回的 items。

## Goals / Non-Goals

**Goals:**

- 流式分析成功后，喂养页立即展示 result 中的 items。
- 去掉「跨日内存过期」展示过滤，避免错误 `day` 格式误伤。
- 保持 `ready` / `loading` / `failed` 门闩与（若保留）推演关闭 id 过滤。

**Non-Goals:**

- 不改正服务端 `day` 字段语义或格式。
- 不改 SSE 协议、日限、资格、开通、思考流 UI。
- 不恢复预测页跑马灯或跨日自动 daily。
- 不新建 `**/test/**`。

## Decisions

1. **删除派生列表的 dayKey 相等判断**  
   在 `predictionCareAlertProvider` 去掉 `st.dayKey.isNotEmpty && st.dayKey != day → []`。展示条件保留 `!st.ready || st.failed || st.loading → []`。  
   **备选（否决）**：规范化服务端 `day` 再比较——仍把错误契约留在客户端，且现网 `day` 更像生成时刻而非自然日键。  
   **备选（否决）**：仅流式路径强制写本地 `careAlertShanghaiDayKey()`——治标，过滤逻辑仍复杂且与「信服务端」原则不符。

2. **`dayKey` 字段可保留作元数据**  
   state / 日志仍可记录服务端 `day` 或本地日键，但不参与是否渲染列表。无需为本变更删除字段。

3. **推演关闭集合过滤保留**  
   `forecastDisabledIdsProvider` 与「跨日过期」无关；本变更不改动，除非后续产品要求一并简化。

## Risks / Trade-offs

- **[Risk] 喂养页开着跨过 0 点仍显示旧快照** → 可接受；退出再进 hydrate 或再点分析即可；与「信服务端 latest」一致。  
- **[Trade-off] 客户端不再强制「仅今日」** → 日界由服务端 latest/stream 缓存策略负责。  
- **[Risk] 其它隐藏消费者依赖「跨日变空」** → 现网仅喂养页 watch 该派生 provider；改前再 grep 确认。

## Migration Plan

- 纯客户端行为修复；发版即可。  
- 回滚：恢复 dayKey 比较（不推荐，除非同步修正服务端日键格式）。

## Open Questions

- （无）产品已确认不需要本地日过滤。
