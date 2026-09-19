## Context

喂养分析手动生成走 `CareAlertRepository.analyzeStream`，成长轨迹走 `GrowthTrajectoryRepository.turnStream`。两条路径都用裸 `http.Client` 读 SSE，只在 `statusCode != 200` 时把 body 当 `{code, message}` 解析。

日限在 Go 控制器写 SSE 头之前返回 `gerror`。`MiddlewareHandlerResponse` 包成 HTTP 200 的 `{code, message, data}`（值得留意 `40304` / 文案「今日值得留意分析次数已用完，请明日再来」；成长轨迹同类）。网关反代不改这个壳。`ApiClient._decodeResponse` 已按「HTTP 200 且 `code != 0`」当业务失败；两条 SSE 客户端没有。

结果：200 的 JSON 被当成 SSE 逐行丢掉，喂养分析落到「分析失败，请稍后重试」，成长轨迹落到本地通用失败文案。

## Goals / Non-Goals

**Goals:**

- 预检失败的 HTTP 200 业务 envelope 必须把非空 `message` 交给现有 Toast。
- 真正的 `text/event-stream` 思考流行为不变。

**Non-Goals:**

- 不改 Go HTTP 状态码、日限规则、SSE 事件协议。
- 不改 UI 文案表，不新增测试文件。
- 不把网络超时、断流改成展示异常对象字符串。

## Decisions

1. **认 envelope，不改服务端状态码**  
   与仓库其余接口一致：HTTP 200 + `code != 0` 即业务失败。改成非 200 会和 `ApiClient`、网关习惯分叉。

2. **用 `Content-Type` 分流，并兜底首包 JSON**  
   SSE 成功路径的 `Content-Type` 含 `text/event-stream`。预检 envelope 是 `application/json`。客户端在开 SSE 解析前：若状态非 200，或 `Content-Type` 含 `application/json`，整段 body 按 envelope 取 `message`。  
   若 `Content-Type` 缺失或被改写，再看 body 是否为带 `code` 且 `code != 0` 的 JSON 对象；是则同样取 `message`。已出现 `event:` / `data:` 的流不回退成 envelope。

3. **解析放在两个 repository，不改 provider 文案表**  
   喂养分析 yield `CareAlertStreamErrorEvent`（带上 envelope 的 `code` 字符串）。成长轨迹抛 `ApiBusinessException`，与现有非 200 分支一致，provider 已 Toast `e.message`。空 `message` 仍用各自现有兜底句。

4. **不共享新模块**  
   两处各写一个小的 envelope 判断即可，避免为两段解析再抽公共层。

## Risks / Trade-offs

- **[Risk] 网关剥掉 `Content-Type`** → 用「尚未进入 SSE 帧时，整段 body 是 `code != 0` 的 JSON」兜底。
- **[Risk] 成功 SSE 的某一行碰巧是 JSON** → 只在还没有任何 `event:` / `data:` 时做整包判断，不在流中途改判。
- **[Trade-off] 两处解析略重复** → 比新公共 API 更不容易误伤其它 HTTP 客户端。

## Migration Plan

- 只发 Flutter。旧服务端 envelope 形状不变，新客户端即可 Toast 原文。
- 回滚：恢复「仅非 200 读 message」。

## Open Questions

- （无）预检文案以服务端 `message` 为准，客户端不改写日限句子。
