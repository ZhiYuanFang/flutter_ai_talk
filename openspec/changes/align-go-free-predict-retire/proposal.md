## Why

产品竞争力收束到**喂养预测**：Go 已落地 `predict-pro-unlock-shell`（删基础包、推送全员开放、仅留 Pro 开通壳）与 `retire-non-predict-ai-surface`（硬删 VIP 商业面 / 值得留意 / 成长轨迹 / 诊疗等；Apple 验单历史路径已恢复为功能/小智履约）。Flutter 仍跑双轨种子、basic 试用、VIP settle、三档墙与 AI 分析 Hub，并把验单成功误绑 VIP status。需对齐 Go，砍间隔撑预测，未就绪时在卡上展示亲和进度，并删除无关表面以减包体积与维护成本。

## What Changes

- **预测商业**：取消 `predict_capability_basic` 收费/试用路径；**免费版**为纯客户端标签（无 featureId）；catalog/墙仅突出 **Pro** 开通壳；接线 `GET /cash/app/api/predict-pro/eligibility`（Pro 开通前置，与免费亲和进度分离）。
- **预测算法展示**：删除回忆种子 / 固定间隔撑展示轨 / 双轨 `displayEntitled`；展示仅亲和 `nextAt`；无预测时在**原倒计时区**显示横条进度（桶内 3 次有效发生，≥15min 推进；合并根按根、拆分按子）+ 文案「再有 x 条真实{事件名}记录后…」。
- **能力墙**：由间隔/基础/Pro（含 VIP）改为 **免费版 + Pro版** 两档；去掉 VIP 文案与 basic trial。
- **BREAKING 删除**：VIP 客户端全链（product/status/orders/购页/sticky/`isVip` OR）；值得留意 / care-alert；7 日成长轨迹；诊疗/陪伴 clinic；喂养记录分析及 AI 分析 Hub（含 3h「AI分析」入口）。
- **支付**：Go 已恢复 `POST /cash/app/api/vip/apple/verify`（历史路径兼容；履约仅为功能单/小智，**非** VIP）。Flutter 功能单/小智 IAP **继续打该 URL**；验单成功后刷新 **feature catalog / 小智 unlock**，**不得**再刷 `vip/status`；随 VIP 表面删除把验单从 VIP repository 语义中拆出。
- **顺序**：以 Go 已 merge 行为为准再砍 Flutter；既有 `predict-capability-client` / `settle-gate` / `tier-wall` / `interval-thinking-copy` **留作历史**（本变更 supersede，不删目录）。

## Capabilities

### New Capabilities

- `predict-affinity-progress`：无亲和 nextAt 时卡上进度条与有效发生计数（15min、合并/拆分桶、文案）。
- `predict-free-pro-chrome`：免费版客户端标签 + Pro 墙/Hub 壳；无 basic/VIP/间隔档。
- `retire-vip-care-growth-clinic-client`：客户端删除 VIP、care-alert、成长轨迹、诊疗/陪伴、喂养分析与 AI 分析 Hub。

### Modified Capabilities

- `smart-prediction-page`：3h 后缀改为免费/Pro；去掉 AI分析入口；卡结果区进度 vs 预测切换；去掉种子调间隔作为预测来源。
- `feature-unlock-hub`：去掉 VIP sticky / care / growth / basic；保留 Pro（及小智等仍存活项）。
- `feature-entitlement-client`：去掉 `unlocked || isVip`；预测展示不 entitlement-gate。
- `predict-imminent-client-sync`：pending 与展示统一亲和轨（无种子强制）。

### Superseded（不删仓库目录，仅本变更为准）

- `predict-capability-client`、`predict-capability-settle-gate`、`predict-capability-tier-wall`、`predict-interval-thinking-copy` 中与双轨/basic/VIP/三档/间隔叙事冲突的要求。

## Impact

- **Flutter**：`smart_prediction_*`、`event_next_predictor` 进度 helper、recall seed 栈、`cash_vip_*`、care/growth/clinic/ai-analysis 路由与 provider、Hub、支付 Apple verify、debug 日志 tag、README。
- **依赖 Go**：catalog 无 basic 商业项、trial 仅 Pro、无 App VIP product/status/orders、predict-pro eligibility、历史路径 `vip/apple/verify`（功能/小智语义）。
- **包体积**：删除 clinic WS、成长 SSE、care daily、VIP 购页等大模块。
- **风险**：验单成功后仍 refresh VIP 会误导/空打；未拆 VIP settle 则预测 UI 易卡同步中。
