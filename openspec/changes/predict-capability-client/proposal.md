## Why

Go 侧已落地预测能力基础版 / Pro（`predict_capability_basic` / `predict_capability_pro`）与 7 日点试用、imminent 推送门禁；Flutter 仍按「本地亲和算法一达标就静默取代固定间隔」展示，且未对接点试用与能力态 UI。需要把**展示轨**与**静默上传轨**拆开，对齐商业开通漏斗，并修复按根间隔种子被误清导致的并存 bug。

## What Changes

- 对接 catalog 两档功能 ID；新增 `POST /cash/app/api/feature/trial/start` 客户端；Pro 开通/试用 CTA 统一提示「功能尚未上线」。
- **双轨预测**：静默轨始终跑亲和算法并用于 imminent pending 上传；展示轨在无 basic∨pro∨VIP 有效覆盖时**强制种子间隔**（含预测卡、喂养 tip、「接下来3小时」、桌面小组件）；有覆盖时展示与亲和一致。
- 任一事件亲和可产出 nextAt 且本宝宝未提醒、且无 basic/pro/VIP → 玻璃弹窗告知「智能预测基础版已生效…」；**弹窗一出即标记已提醒**；「立即体验」直接点试用，不进开通页。
- 预测页在「接下来3小时」与事件列表之间增加**预测能力卡**（类型 / 到期；有算法根且未开通称「基础版待开通」）；点击进功能开通页。
- 固定间隔展示期间，预测时刻旁增加调间隔小按钮；按根保留种子与算法并存；修正「原始样本达标即清种子、亲和却失败」导致永久「补充大概多久一次」的 bug。
- 到期仅改能力卡/展示轨回固定间隔文案与种子展示；亲和继续静默运行并上传。

## Capabilities

### New Capabilities

- `predict-capability-display-rail`：展示轨 vs 静默轨、权益门闸、全展示面跟展示轨。
- `predict-capability-onboarding`：宝宝维已提醒缓存、算法就绪玻璃弹窗、点试用成功弹窗。
- `predict-capability-status-card`：预测页能力卡位置、文案态、进开通页。

### Modified Capabilities

- `feature-entitlement-client`：识别预测两档；展示覆盖合成 `basic∨pro∨VIP`；点试用 API；与 Go catalog VIP 不改写 `unlocked` 并存。
- `feature-free-trial`：预测两档走 7 日点试用（非 care/growth 的 soft+24h claim）。
- `feature-unlock-hub`：展示基础版/Pro 卡；Pro CTA 未上线拦截；基础版可支付/邀请/点试用。
- `prediction-recall-seeds`：清种子门闸与展示轨对齐；按根与算法并存。
- `smart-prediction-page`：能力卡插入；固定间隔展示时时刻旁调间隔。
- `predict-imminent-client-sync`：pending 必须取自静默亲和轨（不得改用展示轨种子时刻顶替上传）。

## Impact

- **代码**：`feature_unlock_*`、`smart_prediction_*`、`event_next_predictor` / `prediction_recall_*`、`home_widget_*`、tip / 3 小时时间线、玻璃弹窗、account wipe（宝宝维提醒标记）。
- **API**：`GET feature/catalog`（已有两档）；`POST feature/trial/start`；Pro eligibility 本轮可不接真开通（CTA 未上线即可）。
- **对齐**：兄弟仓 `go_ai_talk` change `predict-capability-unlock`（已完成）。
- **基线**：对照 `openspec/specs/v2.2.1.md` 中上述 Modified 能力；不复活 `prediction_unlock` 槽位模型。
