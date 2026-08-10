## Context

智能预测页「值得留意」已由 `prediction-care-alert-banner` → `prediction-care-alert-marquee-list` 落地为本地双基准规则引擎 + 按事件聚合跑马灯 + 详情结构化原因。产品要求改为 **Go 编排 + Python KG/LLM 日分析**，服务端按宝宝日缓存，多看护共享忽略结果；Flutter 删除本地引擎与失败回退。

冻结决策（含「全按建议」6 项）见 proposal；本设计固化 API 形状与客户端接线。

## Goals / Non-Goals

**Goals:**

- Flutter 每日一次（逻辑日）拉取服务端列表，填充既有跑马灯 / 详情 DTO。
- 「值得留意」卡片常驻：加载中「加载中…」；成功空列表无标题「宝宝成长得真棒！」可点进陪伴；失败「接口异常」+ 刷新；有条目则跑马灯。
- 忽略单条：本地立刻消失 + Go 删当日缓存项 + 飞轮 `ignore`；追问：树洞原样注入 `followUpPrompt` + 飞轮 `follow_up`。
- 推演关闭客户端过滤；VIP→DeepSeek / 非 VIP→Zhipu 由 Go 选模。
- 在本仓写清 Go/Python 契约；Flutter 对真实路径发请求。

**Non-Goals:**

- 不与 clinic 配额耦合。
- 不对忽略/追问自由文本做 NLP。
- 不在本仓实现 Python LLM / KG 本体；不在本仓实现 Go 缓存存储细节（仅契约与 Flutter 客户端）。
- 不自动新建 `**/test/**` 测试文件。

## Decisions

### D1：缓存键与 GET 语义

- **键**：`deviceNo`（宝宝设备维度）+ 自然日 `YYYY-MM-DD`（`Asia/Shanghai`）。
- **GET**：命中缓存 → 返回相同列表、**不**重跑 LLM；未命中 → **阻塞等待**首次生成（服务端 single-flight）；生成失败 → 非 2xx / 业务错误，客户端当失败处理。
- **客户端**：同一 `deviceNo+day` single-flight；provider 创建不得自动乱打；由预测页可见时显式 `ensure`。失败**不**熔断：同日成功才幂等跳过；失败后再次进入预测页仍须重试。

### D2：HTTP 路径（约定，Go 实现）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/device/api/care-alert/daily` | Query：`deviceNo`。响应 `data.items: CareAlertDto[]`。可选 `data.day`（上海日）。超时建议 ≥60s（首次生成）。 |
| DELETE | `/device/api/care-alert/daily/item` | Query：`deviceNo`, `suggestionId`（与现有 `ApiClient.deleteEnvelope` 对齐；Go 亦可同时接受 JSON body）。从**当日**缓存移除该项；成功后其他看护再 GET 见更新后列表。 |
| POST | `/device/api/care-alert/feedback` | Body：`deviceNo`, `suggestionId`, `intent` ∈ {`ignore`,`follow_up`}。固定意图飞轮，**无**反馈文本 NLP。 |

响应 envelope 与仓库一致：`{ code, message, data }`，`code==0` 成功。

### D3：DTO → Flutter 形状

服务端每项至少：

```json
{
  "suggestionId": "<uuid>",
  "eventId": "...",
  "eventName": "...",
  "summaryLine": "...",
  "followUpPrompt": "...",
  "reasons": [
    {
      "type": "elongatedInterval|longActive|suddenAbsence|<string>",
      "score": 0.0,
      "expectationUsed": true,
      "ageMonths": 3,
      "medianGapMs": 0,
      "lastGapMs": 0,
      "expectGapMaxMs": 0,
      "p75DurMs": 0,
      "elapsedMs": 0,
      "expectDurMaxMs": 0,
      "dailyAvg": 0.0,
      "recent48hCount": 0,
      "stillExpected": true,
      "detailLines": ["可选补充说明"]
    }
  ]
}
```

- Flutter 映射为 `CareAlertEventItem`（增加 `suggestionId`、`followUpPrompt`）+ `List<CareAlertReason>`。
- 未知 `type`：映射为可展示标签（原文字符串或「其他」），不得整项丢弃（除非缺 `suggestionId`/`eventId`）。
- 时长字段用 ms（或 ISO duration）；解析失败则该字段置空，仍可展示摘要。

### D4：加载 / 失败 / 空列表 UI（卡片常驻）

- **卡片始终渲染**「值得留意」外壳。
- **Loading**（含尚未 ready）：正文「加载中…」，不可点进详情。
- **Failure**：正文「接口异常」，标题行右侧刷新 → `ensureLoaded(force: true)`；可打 `AppDebugLog`，不 Toast 轰炸；**禁止**本地规则引擎回退。
- **Success + 过滤后空**：不展示标题「值得留意」；正文「宝宝成长得真棒！」；整卡点击进入陪伴/树洞。
- **Success + 非空**：跑马灯；点进详情。
- **「接下来3小时」**：与留意列表解耦；有窗内预测段落即展示（不要求留意非空）。

### D5：忽略与追问

- **忽略**：乐观本地从列表移除该项 → `context.pop` → `DELETE` 缓存项 + `POST` feedback `ignore`（二者可并行，均须鉴权；DELETE/feedback 用户点击触发，非 listener 副作用环，但仍建议 in-flight 去重按 `suggestionId`）。
- **追问**：`POST` feedback `follow_up`（可 fire-and-forget 带日志）→ 打开 `/companion` 并携带 `followUpPrompt` 作为用户侧预填/自动发送文案（原样，prefer B）；不得改写 prompt。
- 全部忽略后列表空 → 无标题空态「宝宝成长得真棒！」，点击进陪伴。

### D6：模型与 VIP

- Go 读账号 VIP 字段（若存在且为真 → DeepSeek，否则 Zhipu）；Flutter **不**选模，仅可透传已有 session 字段若 Go 需要（通常 Go 自查）。
- Python 接收模型标识后执行 KG+LLM；**无** clinic 配额扣减。

### D7：推演关闭过滤

- 保持客户端过滤：`forecastDisabledIdsProvider` 排除后再展示；与 `prediction-forecast-toggle-restore` 一致。

### D8：删除本地引擎

- 移除 `evaluateCareAlertCandidates` / `aggregateCareAlertsByEvent` / 月龄期望表用于评估的路径；可保留纯展示辅助（`formatCareDuration`、`CareAlertType` 标签、DTO 类）。
- Provider 改为 `AsyncNotifier` / `FutureProvider` 风格暴露 `AsyncValue<List<CareAlertEventItem>>`；UI 仅在 `hasValue && nonEmpty` 显示。

### D9：树洞预填

- 新增轻量入口载荷（如 `CareAlertFollowUpPayload` 或 router `extra` / Riverpod pending prompt）：陪伴页 entry 优先消费该 prompt（填入输入框并发送，或注入为用户消息后发送），再回退既有 widget tip / 问候逻辑。

### D10：跨仓任务边界

- **本仓**：契约文档 + Flutter 全链路。
- **go_ai_talk**：路由反代或本机 handler、缓存、选模、调 Python、DELETE/feedback。契约备忘：`go_ai_talk/openspec/changes/llm-care-alert-daily/CONTRACT.md`。
- **python_ai_talk**：分析服务 endpoint（由 Go 内调）。契约备忘：`python_ai_talk/openspec/changes/llm-care-alert-daily/CONTRACT.md`。

## Risks / Trade-offs

- [首次 GET 阻塞过久] → 超时 ≥60s；UI 不展示面板避免半残；单飞防并发刷。
- [Go/Python 未就绪] → Flutter 对约定路径发真实请求，失败即隐藏；跨仓任务明确未勾选。
- [DTO 字段漂移] → design 锁定最小字段；未知 type 降级展示。
- [多看护竞态] → 忽略以服务端缓存为准；本地乐观更新，下次 GET 对齐。

## Migration Plan

1. 合并 Flutter：删引擎、接 API、UI 隐藏语义。
2. 上线 Go/Python 后同一路径即生效；此前预测页无留意条（可接受）。
3. 回滚：恢复上一版本地引擎 change（不在本次范围）。

## Open Questions

- 无（剩余 6 项用户已「全按建议」冻结）。
