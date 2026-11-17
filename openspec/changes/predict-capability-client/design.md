## Context

Go `predict-capability-unlock` 已提供人对人两档功能、`POST /cash/app/api/feature/trial/start`（7 日起算）、imminent「basic∨pro∨VIP」门禁，以及 catalog 中 VIP **不改写** `unlocked`。Flutter 当前：`predictAllUpcoming` 同时喂预测卡与 `smartPendingPredictionsProvider`；回忆种子在「原始间隔样本达标」时被 `rootIdsWhoseRealHistoryCaughtUp` 清除，而 nextAt 实际依赖亲和样本——易出现按根无 pred、CTA 卡死。产品要求把**商业展示节奏**与**静默算法/上传**拆开。

基线对照：`openspec/specs/v2.2.1.md`（feature-entitlement-client / feature-free-trial / prediction-recall-seeds / smart-prediction-page / predict-imminent-client-sync 等）。

## Goals / Non-Goals

**Goals:**

- 展示轨受 `predictDisplayEntitled = catalog basic∨pro 有效 ∨ isVip` 门闸；未覆盖时全展示面强制种子间隔。
- 静默轨始终亲和；imminent pending **只上传静默轨**。
- 算法就绪首次提醒（宝宝维缓存）+ 弹窗内点试用 basic。
- 预测能力卡 + 开通中心基础版/Pro（Pro 未上线拦截）。
- 按根间隔与算法并存；修清种子门闸；固定间隔展示时时刻旁可调间隔。

**Non-Goals:**

- 实现 Pro 服务端深度学习预测下发。
- 复活 `prediction_unlock` 槽位模型。
- 改 Go imminent 门禁语义（仅对齐消费）。
- 为 care/growth 改点试用（仍 soft+24h）。
- 自动新建 `**/test/**`。

## Decisions

### D1：双轨在 `buildSmartPredictionBundle`（或紧邻层）拆分

- **选择**：一次（或并行）算出 `algoPredictions`（现有亲和+种子 fallback 逻辑，供静默）与 `displayPredictions`（未 entitle 时对有种子的根强制 `lastAt+seed.interval`，忽略亲和胜出；无种子则该根展示无 pred）。
- **备选**：两套 provider 各跑一遍预测——浪费且易漂移。
- **理由**：今天 bundle 已同时产出 `rows` 与 `pendingPredictions`，是最小切开点。

```
predictAllUpcoming / 亲和
        │
        ├─► pendingPredictions（静默，始终）
        │
        └─► display overlay
              entitle? ──yes──► rows/tip/3h/widget = algo
                   │
                   no ──► 有种子则 seed nextAt；否则 null
```

### D2：展示覆盖合成独立于 catalog `unlocked`

- **选择**：`isPredictDisplayEntitled = basicActive || proActive || isVip`；basic/pro Active 来自 catalog 对应项 `unlocked && (expiresAt==0 || expiresAt>now)`（VIP 时 Go 可能仍 `unlocked=false`，故必须 OR isVip）。
- **备选**：仅看 `unlocked`——VIP 用户会错误掉回种子展示。
- **理由**：与 Go 使用态 OR 一致，又尊重 catalog 不因 VIP 改写 unlocked。

### D3：提醒标记在「弹窗展示」瞬间写入

- **选择**：`showGlassDialog` 即将展示（或 `builder` 首帧）即按 `deviceNo` 持久化 `algoReadyReminded=true`；取消不再弹；「立即体验」同窗内 `trial/start`。
- **键**：宝宝维（deviceNo）；账号 wipe / 清 deviceNo 时清除（对齐 `wipeAccountLocalState`）。
- **触发**：已绑定会话下，静默轨出现**至少一个**非预约根亲和可产出 nextAt，且未提醒，且 `!isPredictDisplayEntitled`。

### D4：清种子门闸与展示轨对齐

- **选择**：废除「仅 raw `historyMeetsPredictorSampleGate` 即 drop」。改为：
  - 无真 lastAt（窗+缓存）→ 可 drop（既有 empty 规则保留）；
  - **未 entitle** → **不得**因算法就绪 drop 该根种子（展示依赖）；
  - **已 entitle** 且该根静默亲和已能独立产出 nextAt → 可 drop。
- **理由**：直接修复「别的事件达标、本事件种子被误清」；保证按根并存。

### D5：开通中心 Pro

- **选择**：catalog 展示 Pro 卡；支付/邀请/试用 CTA 点击 → Toast/玻璃提示「功能尚未上线」，不调 eligibility、不建单、不 trial/start。
- **基础版**：支付/邀请按既有 hub；试用可走确认后 `trial/start`（与弹窗同 API），成功后刷新 catalog。

### D6：能力卡文案优先级

1. pro 有效（人权益）→「预测能力 Pro」+ 到期文案（即使本轮不能新开）  
2. basic 有效 →「智能预测基础版」+ 到期  
3. isVip 且无人权益 →「VIP 已覆盖预测推送」类文案（不上报成已购功能行）  
4. 有任一算法根且未 entitle →「基础版待开通」  
5. 否则 →「固定间隔」

点击 → `/feature-unlock`（或既有开通路由），可锚到 basic 项。

### D7：调间隔入口

- 展示轨该卡 `nextAt` 来自种子（或未 entitle 且有种子）时，在预测时刻文案旁挂小按钮 → 复用既有 interval picker，`upsertSeed` 后重算展示轨并触发 pending 同步（静默轨可能仍用亲和）。

### D8：日志

- 新诊断走 `AppDebugLog`；新 tag 三联改（`app_debug_log.dart` / `logcat_api_http.ps1` / `README` Debug 表）。禁止裸 `print`。

## Risks / Trade-offs

- [未 entitle 时展示与 pending 时刻不一致] → 可接受：Go 未开通不推送；开通后两轨合一。文档化避免客服误解。  
- [无种子但亲和已能算] → 展示无 pred，出「补充大概多久一次」；静默仍上传。可能短暂「有上传无卡点」——用能力卡「基础版待开通」引导体验后切展示。  
- [VIP 能力卡文案 vs catalog unlocked=false] → 能力卡走 D2/D6，勿只信 unlocked。  
- [弹窗即标记导致误触取消丢提醒] → 产品已拍板；开通页仍可点试用。  
- [Pro 假门面] → CTA 明确未上线，避免误扣费。

## Migration Plan

1. 发版后旧种子数据兼容；清种子逻辑变更不迁移 DB。  
2. 提醒标记默认 false → 符合条件用户见一次弹窗。  
3. 回滚：去掉双轨覆盖即可回到「展示=亲和」；商业 API 调用可 feature-flag 或直接留无害。

## Open Questions

无（探索已拍板）。实现时若开通路由锚点 ID 与 hub 列表滚动 API 不存在，则退化为打开开通页首页。
