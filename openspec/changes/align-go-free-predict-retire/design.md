## Context

Go 已 merge：`predict-pro-unlock-shell`（catalog 去掉 basic 商业项、推送全员开放、仅留 Pro 开通壳 + `GET /cash/app/api/predict-pro/eligibility`）与 `retire-non-predict-ai-surface`（硬删 VIP 商品/状态/建单与 care/growth/clinic 等；并恢复历史路径 `POST /cash/app/api/vip/apple/verify` 供功能/小智加速履约）。Flutter 仍实现双轨（展示种子 vs 静默亲和）、`predict_capability_basic` 试用、VIP settle 门闸、三档墙、AI 分析 Hub，且验单成功后仍可能 refresh VIP status。

基线：`openspec/specs/v2.2.1.md`；未归档历史 change：`predict-capability-client` / `settle-gate` / `tier-wall` / `interval-thinking-copy`（本变更 supersede，目录保留）。

## Goals / Non-Goals

**Goals:**

- 预测展示与 pending 统一为**单轨亲和** `nextAt`；无亲和结果时在卡原倒计时区展示亲和进度。
- 商业面仅 **免费版**（客户端标签）+ **Pro版**（catalog `predict_capability_pro`）；去掉 basic/VIP/间隔档叙事。
- 客户端硬删 VIP、care-alert、成长轨迹、诊疗/陪伴、喂养分析与 AI 分析 Hub；3h 去掉「AI分析」。
- 功能单 / 小智 IAP 验单改接到 Go 现网入口（实现前核对路径）；不再调用已死 VIP Apple verify。
- 清理 `isVip` OR 覆盖、VIP settle 副作用门闸依赖；预测 UI 不再 await VIP。

**Non-Goals:**

- 实现 Pro 服务端定制预测算法下发（仅开通壳 / eligibility / trial 若 Go 仍开放）。
- 删除仓库内历史 OpenSpec change 目录。
- 改 Go 已退休 API 行为。
- 自动新建 `**/test/**`。
- 复活 `prediction_unlock` 槽位模型。

## Decisions

### D1：单轨亲和，废除双轨与展示 entitlement

- **选择**：删除 `displayEntitled` / silent vs display 拆分；`predictAllUpcoming`（及 tip / 3h / widget / pending）均消费亲和轨 `nextAt`。
- **备选**：保留双轨仅改文案——与 Go「推送全员开放、无 basic」冲突，继续依赖 VIP settle。
- **理由**：Go 已去掉展示门闸；Flutter 再 gate 只会卡 syncing / 误弹。

### D2：无 nextAt 时卡上亲和进度（3 点 / ≥15min / 同桶）

- **选择**：对每个预测桶（`predictionBucketKeyForEventId`：合并根按 root、拆分按 leaf）统计**有效发生次数**：按时间排序后，仅当与上一计入点间隔 ≥15 分钟才 +1。目标 = `kMinSamplesForPrediction + 1`（即 2 个间隔样本 ⇒ **3 次**有效发生）。进度 = `min(count, target) / target`。文案：「再有 x 条真实{事件名}记录后即可预估下次时间」（x = target − count，clamp ≥0）。进度 UI 占原倒计时/下次时刻区域；有亲和 `nextAt` 时恢复现有预测展示，不并排进度。
- **备选**：用 raw history 条数 / 不计 15min——与亲和样本门闸不一致，用户会以为「记了 3 条就能预测」。
- **理由**：与 `event_next_predictor` 样本门闸语义一致，合并/拆分桶与预测同源。

### D3：免费版标签 vs Pro catalog

- **选择**：「免费版」**无** featureId、不进 catalog；UI 后缀/墙左档为客户端常量。右档仅 `predict_capability_pro`（支付/邀请/试用按 Go catalog + eligibility）。删除 `predict_capability_basic` 常量路径、点试用、VIP→基础版映射。
- **备选**：伪造本地 basic catalog 行——与 Go 目录冲突，易再引入 settle。
- **理由**：对齐 Go Pro-only 壳。

### D4：两档墙替换三档墙

- **选择**：3h 标题后缀仅 `· 免费版` / `· Pro版`（Pro 有效优先）；点击开全屏两档说明（carousel 可保留两页）。去掉「间隔版」「基础版」与 VIP 文案。settle syncing 占位改为轻量「同步中」仅当仍需 await **catalog/pro eligibility**（**不得**再 await VIP）。
- **备选**：完全去掉后缀——产品仍要轻量档位入口。

### D5：回忆种子降级

- **选择**：种子**不再**作为展示预测来源，也不再强制 display rail。冷启动「大概多久一次」若仍保留，仅作可选 UX / 算法 fallback（亲和样本不足时 predictor 内部可用），但卡面无亲和 nextAt 时优先进度条而非种子倒计时。清种子逻辑改为：亲和能独立产出 nextAt 即可 drop（不再绑 entitle）。
- **备选**：立刻删全部 interval sheet——范围过大；本变更先断「种子=预测展示」。

### D6：删除表面与路由

- **选择**：硬删客户端：VIP product/status/orders/购页/sticky/`vipStatusProvider` 消费路径；care-alert daily/stream/详情；growth trajectory；clinic WS / 诊疗 UI；ai-analysis hub 与 feeding analysis；预测页「值得留意」与「AI分析」。路由与 Hub 卡一并移除；README / debug tag 三联清理。
- **bootstrap**：去掉 VIP 预热、clinic transport 注册等。

### D7：Apple 验单（历史路径复用，非 VIP）

- **选择**：继续 `POST /cash/app/api/vip/apple/verify`（Go `retire-non-predict-ai-surface` 已恢复，供 Flutter 兼容；`CashFeatureController.AppleVerify` → `VerifyAppleIAP`，仅功能 Pro / 小智）。body 不变：`transactionId` / `productId` / `signedTransaction` / `orderNo`。`apple-iap-verify-surface-message` 语义保留（展示服务端 `message`）。成功后刷新 feature catalog / 小智 unlock，**不得** refresh `vip/status`。验单方法从 VIP repository 语义迁出（或保留薄封装但注明非 VIP）。删除 VIP product/status/orders/购页。
- **备选**：新建 `/feature/apple/verify`——Go 已明确用历史路径兼容，不必再造。
- **已关闭**：path 已确认，见上。

### D8：Entitlement helper

- **选择**：`isFeatureEffectivelyUnlocked` = catalog 时间有效 `unlocked`（含 expiresAt）；**去掉** `|| isVip`。副作用 ensure **不得**再 await VIP settle。预测展示 **不得** entitlement-gate。Pro 开通前置走 `predict-pro/eligibility`（与免费亲和进度分离）。

### D9：日志

- 删除 VIP/care/clinic 专用 tag 时同步三联改；新增进度/Pro eligibility 诊断若需要则新 tag + 三联。禁止裸 `print`。

## Risks / Trade-offs

- [验单 URL 含 vip 易误解] → README/注释标明历史兼容路径，履约非 VIP；代码所有权迁出 VIP repo。  
- [成功后仍 refresh VIP] → 任务明确改为刷 catalog/小智；删 vipStatus 消费。  
- [种子用户短暂「无倒计时只见进度」] → 符合产品；文案说明再记 x 条。  
- [历史 OpenSpec 与代码并存] → 本变更为准；旧 change 不删目录以免丢审计。  
- [Hub 变空] → 仅留 Pro + 仍存活项（如小智）；无 VIP sticky。  
- [Widget/桌面预测] → 必须跟单轨；无 nextAt 时 widget 行为在 tasks 中显式对齐（进度或占位，禁止种子伪装预测）。

## Migration Plan

1. 确认 Apple verify 仍打历史 URL + 改成功后刷新目标；接线 Pro eligibility；再删 VIP product/status/orders。  
2. 切单轨与进度 UI；再删双轨/basic/三档代码。  
3. 删 care/growth/clinic/ai-analysis 模块与路由。  
4. 回滚：恢复旧包；服务端已删 VIP 业务 API 无法回滚客户端单飞。

## Open Questions

1. ~~Go Apple 验单 path~~（已关闭：`POST /cash/app/api/vip/apple/verify`，功能/小智语义）。  
2. 冷启动 interval onboarding sheet 是否整段删除，或仅保留「记节奏」UX（默认：保留 sheet，但思考文案与展示不再承诺算法开通）。  
3. 桌面 Widget 在无 nextAt 时显示进度百分比还是静态占位文案（默认：短占位，不做复杂进度条）。
