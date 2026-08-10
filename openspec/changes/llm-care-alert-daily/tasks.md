## 1. Flutter DTO 与本地引擎拆除

- [x] 1.1 扩展 `CareAlertEventItem`：增加 `suggestionId`、`followUpPrompt`；必要时扩展 `CareAlertReason` 以解析服务端字段（含未知 type / detailLines）
- [x] 1.2 删除本地评估路径（`evaluateCareAlertCandidates` / `aggregateCareAlertsByEvent` / 月龄期望评估调用链）；保留展示辅助（标签、`formatCareDuration` 等）
- [x] 1.3 新增 API JSON → `CareAlertEventItem` 解析（对齐 design D3）

## 2. Flutter 日拉取与副作用治理

- [x] 2.1 在 Feed/API repository 增加 `GET /device/api/care-alert/daily`（query `deviceNo`，超时≥60s）与 `DELETE .../item`、`POST .../feedback`
- [x] 2.2 重写 `predictionCareAlertProvider`：按 `deviceNo`+上海自然日 ensure、single-flight、失败不熔断（再进预测页重试）、成功会话缓存
- [x] 2.3 成功列表再按 `forecastDisabledIdsProvider` 客户端过滤；空列表供空态文案
- [x] 2.4 若新增 Debug tag：三联改 `app_debug_log.dart` / `logcat_api_http.ps1` / `app/README.md`（否则复用既有 tag 并打 err=）

## 3. Flutter UI：跑马灯、详情忽略/追问、树洞预填

- [x] 3.1 `smart_prediction_screen`：值得留意卡片常驻（加载中/空态真棒/失败刷新/跑马灯）；接下来3小时与留意非空解耦
- [x] 3.2 详情页增加「忽略」「追问」：忽略=本地移除+pop+DELETE+feedback `ignore`；追问=feedback `follow_up`+打开树洞并原样传入 `followUpPrompt`
- [x] 3.3 陪伴入口消费 care-alert 预填载荷（优先于 widget tip/问候），原样填入/发送

## 4. Go 契约（兄弟仓 `go_ai_talk`，本仓文档+可选 stub）

- [x] 4.1 实现/反代 `GET /device/api/care-alert/daily`：缓存键 `deviceNo+Asia/Shanghai day`；命中不重跑 LLM；未命中 single-flight 阻塞生成
- [x] 4.2 实现 `DELETE /device/api/care-alert/daily/item`：仅删当日缓存中该 `suggestionId`
- [x] 4.3 实现 `POST /device/api/care-alert/feedback`：固定意图 `ignore`|`follow_up`，转发飞轮；无 NLP
- [x] 4.4 VIP 字段选模（VIP→DeepSeek，否则 Zhipu）；调用 Python 分析；不扣 clinic 配额；每项生成 UUID `suggestionId` 与 `followUpPrompt`（Go 已落地；Python analyze/feedback 仍待就绪，见 Python CONTRACT）

## 5. Python 契约（兄弟仓 `python_ai_talk`）

- [x] 5.1 提供 Go 可调用的护理留意分析接口：输入宝宝上下文（月龄、历史、KG）；输出可映射 D3 的 items 列表
- [x] 5.2 按 Go 传入模型标识执行 LLM；不与 clinic 配额耦合

## 6. 校验

- [x] 6.1 `openspec validate llm-care-alert-daily --strict` 通过
- [ ] 6.2 Flutter 侧手工路径：加载中文案 → 空态真棒 / 失败刷新 / 成功跑马灯 → 忽略后空态 → 追问进树洞预填
