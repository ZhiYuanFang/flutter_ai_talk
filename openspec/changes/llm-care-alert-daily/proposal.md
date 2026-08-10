## Why

本地规则引擎「值得留意」无法利用知识图谱与大模型做月龄/历史对照，且无法在多看护人间共享同一日结果与忽略状态。需要改为服务端日缓存 + LLM 生成列表，Flutter 仅展示与反馈，去掉本地规则与失败回退。

## What Changes

- **BREAKING**：删除 Flutter 本地护理留意规则引擎（`evaluateCareAlert*` / 月龄期望表评估路径）；「值得留意」**仅**消费服务端日缓存列表（无本地 fallback）。
- 「值得留意」**卡片常驻**：加载中「加载中…」；成功空列表「宝宝成长得真棒！」；失败「接口异常」+ 刷新；有条目则跑马灯。
- 新增每日一次（按宝宝 / `deviceNo` + Asia/Shanghai 自然日）的 GET：服务端缓存命中则返回相同列表且不重跑 LLM；首日生成 GET **阻塞等待**（服务端 single-flight）；客户端亦 single-flight。
- API 返回 **列表**（非 Top1），映射进既有 `CareAlertEventItem` / `CareAlertReason` 形状，驱动现有跑马灯。
- 每条建议带服务端生成、当日作用域的 `suggestionId`（UUID）；忽略只删 **当日** 缓存项（次日可再出现）；全部忽略后 → 空态文案（卡片不隐藏）。
- 详情：**忽略** = 本地移除 + pop + Go 删缓存项 + 飞轮固定意图 `ignore`；**追问** = 进入树洞并携带 API 提供的 `followUpPrompt`（原样注入）+ 飞轮固定意图 `follow_up`（不对反馈文案做 NLP）。
- 推演关闭事件：客户端过滤；VIP 读既有账号字段（有则 VIP→DeepSeek，否则非 VIP→Zhipu）——**模型选择在 Go**，Python 执行 LLM；**不**与 clinic 配额耦合。
- OpenSpec 主变更在本 Flutter 仓；Go 编排 / Python KG+LLM 以契约任务形式引用兄弟仓实现。

## Capabilities

### New Capabilities

- `llm-care-alert-daily`：服务端日缓存护理留意列表的客户端拉取、常驻卡片空态/错误态、忽略/追问 HTTP 与树洞预填、飞轮固定意图反馈（不含 NLP）。

### Modified Capabilities

- `prediction-care-alert`：由本地规则引擎评估改为服务端列表驱动；废除「评估不得仅为 HTTP」与本地阈值规则作为唯一来源；保留跑马灯列表形态、详情结构化原因语气、推演关闭客户端过滤；空列表改展示正向空态文案。
- `smart-prediction-page`：留意卡片常驻；有条目跑马灯，否则加载/空态/错误态文案；「接下来3小时」与留意非空解耦。

## Impact

- Flutter：`prediction_care_alert.dart`（删引擎/改 DTO）、`prediction_care_alert_provider.dart`（异步日拉取 + 过滤）、`prediction_care_alert_screen.dart`（忽略/追问）、`smart_prediction_screen.dart`、API client/repository、树洞入口预填、Debug 日志 tag（若新增）。
- Go（兄弟仓 `go_ai_talk`）：日缓存 GET/忽略 DELETE（或等价）、VIP 选模、编排调用 Python、飞轮固定意图上报代理。
- Python（兄弟仓 `python_ai_talk`）：KG + LLM 分析（月龄/历史/KG），产出可映射 `CareAlertEventItem` 的列表与 `followUpPrompt`；执行所选模型推理。
- 副作用 HTTP：日拉取须 single-flight + 同日成功幂等；失败不熔断，再进预测页重试（`project.md`）。
