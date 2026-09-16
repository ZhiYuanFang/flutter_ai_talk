## Context

当前商业开通在 cash 域混用：

- **主体**：care → `feature_entitlement`（device）；growth → `feature_user_entitlement`（user）；预测 → `feature_allowed_count`（槽位）。
- **期限**：care 支付永久；growth 支付 30d；邀请/广告多为 7d。
- **试用**：仅客户端「恭喜获得试用资格」文案 + 邀码框，无服务端 trial 记账。
- **额度**：care Redis 按 `device_no` 日缓存短路；growth 按 `wxId` 日 5 次。
- **结果**：care/growth latest 均按 `device_no`，全家共享。
- **邀请**：同宝宝禁兑、`InviteOncePerDevice`（care）、`InviteOncePerUser`（growth）并存。
- **客户端**：Hub 未达标直跳喂养；未开通弹邀码；设置头像下开通摘要；开通中心含看广告与预测槽位卡。

本变更双端（Flutter + `go_ai_talk`）一次收拢为用户维期限模型 + 真实免费体验。无存量付费迁移负担。

## Goals / Non-Goals

**Goals:**

- 权益、试用、邀请次数、日额度全部 **按用户**。
- 支付 30d / 邀请 7d / 试用成功后 24h；删除广告与预测槽位。
- soft access：可进详情、可多次生成；**首次成功** claim。
- 结果键 `(wx_id, device_no)`；进详情加载最新缓存不扣次。
- Hub/详情/设置/开通页 UX 按 proposal 调整。

**Non-Goals:**

- 不改 VIP 月卡履约模型（仍可合成覆盖 care/growth `unlocked`）。
- 不改 UCG 入场喂养资格、不改喂养达标门闸本身（care 体验/分析仍依赖达标）。
- 不做永久 care SKU 存量割接。
- 不新建 `**/test/**`。
- 不在本变更引入新 Android 原生 SDK。

## Decisions

### D1. Soft access + 成功后 claim（方案 A）

- **判定可分析**：`VIP || user_entitlement 未过期 || trialAvailable`（care 另需喂养达标）。
- **Claim 触发**：care/growth **生成成功并落最新结果** 的同一事务/紧随路径中；若 `trialAvailable` 且此前无有效权益，则：
  1. `feature_user_trial (wx_id, feature_id)` unused → used
  2. `ActivateFeature(channel=trial, subject=user, duration=24h)`
- **试用窗内多次生成**：允许，受用户日 5 次约束；仅**第一次成功**触发 claim。
- **放弃中途**：不写 trial、不写权益。
- **备选否决**：弹窗即 claim — 用户未完整体验却消耗资格。

### D2. Catalog 字段

```
trialAvailable   // !有效开通 && trial 未 used（VIP 合成 unlocked 时为 false）
inviteAvailable  // unlock_methods 含 invite_code && 该人该功能无邀请成功记录
```

客户端：VIP/已开通不展示免费体验；`inviteAvailable=false` 不展示邀请入口；广告字段可忽略/删除。

### D3. 结果与额度键

| 能力 | 最新结果 | 日额度 |
|------|----------|--------|
| care | 持久/缓存键 `(wx_id, device_no)`；取消「仅 device 日缓存短路」 | Redis/计数：`wx_id + feature + 上海日`，默认 5，每次成功刷新 |
| growth | MySQL latest PK/唯一键改为含 `wx_id`（保留 `device_no`） | 已有 wxId 日限，保持 5 |

进详情：先 GET latest（不 INCR）；点分析成功后再计次 + 可能 claim。

### D4. 邀请规则终态

允许当且仅当：码有效、非本人码、人×码×功能未兑过、功能支持 invite、**人×功能尚未有任意邀请成功**（`InviteOncePerUser` 扩至 care+growth）。

删除：同宝宝校验、`InviteOncePerDevice`、ad 渠道激活。

### D5. 删除预测槽位

- Go：停用/下线 `prediction_unlock` 定义与 allowed_count 履约；catalog 不再下发该项（或 status=0 且客户端过滤）。
- Flutter：删除 `FeatureLockOverlay` 槽位逻辑、满额邀码开槽、开通中心预测槽位卡 CTA、`allowedCount` 相关 helper。
- 预测页：登录用户可见事项不再因槽位锁定。

### D6. UX 入口矩阵

```
喂养 Hub 卡
  未达标 → 确认弹窗 → 用户确认后才 requestPage(feeding)+go home
  达标未开通 → 介绍弹窗（无输入框）：[¥x 支付] [其它方式→/features/unlock]
  已开通/VIP/soft trial 可进 → 详情

成长 Hub 卡
  未开通 → 同上介绍+支付弹窗
  可进 → 详情

开通中心未开通卡按钮行
  [支付开通] [邀请码?] [免费体验?]
  邀请码仅 inviteAvailable；免费体验仅 trialAvailable（care 另需客户端知悉喂养达标，不达标可灰/隐藏）

设置
  登录后宝宝卡下方「功能开通」卡 → /features/unlock
  删除头像下开通摘要
```

详情 care：分析 CTA + 小字从 AppBar 挪到正文下方居中；小字改为与「用户每日最多 5 次」一致（勿再写「每日仅一次」）。

### D7. Claim 实现落点（Go）

- 不单独强迫客户端调 `POST .../trial/claim` 作为主路径（可保留内部函数）；**权威 claim 挂在 voice 成功落库之后**，由服务端根据「本次请求以 trial soft 放行且 trial 未 used」自动写入。
- 客户端成功回调后 `refresh` catalog 即可看到 `unlocked` + `trialAvailable=false`。
- 开通页「免费体验」：确认弹窗文案「每位用户仅一次…」→「体验」→ push 详情（不写库）。

### D8. Care 支付 SKU

种子改为 30 天产品（新 productCode 或改现网种子）；`duration_days=30`；无永久。

## Risks / Trade-offs

- **[Risk] 双端发布窗口不一致 → 旧客户端仍调 ad/槽位** → Mitigation：Go 对 ad/prediction_unlock 返回明确不可用；catalog 不下发；旧客户端降级为无按钮或错误 toast。
- **[Risk] soft access 被刷多次 LLM 后不 claim（杀进程）** → Mitigation：日额度 5 仍约束；可接受获客成本。
- **[Risk] 原 device 维 care 权益残留** → Mitigation：读路径只认 user 表；可选一次性忽略旧 device 行（无付费存量）。
- **[Risk] 全家共享结果消失，家长 B 看不到 A 的分析** → Mitigation：产品明确接受用户隔离；文案不承诺家庭共享。
- **[Trade-off] 预测全开可能增加预测计算负载** → 接受；原槽位本就体验差。

## Migration Plan

1. Go：schema（`feature_user_trial`）、catalog 字段、邀请瘦身、care 权益改 user、SKU 30d、结果键迁移（新键读写；旧 device-only 行可读降级一期后弃）、日额度、删 ad/槽位履约。
2. Flutter：契约字段 → Hub/弹窗/详情/开通页/设置 → 删槽位代码。
3. 联调：试用 A 路径、邀请一次、支付 30d、日 5 次、换账号结果隔离。
4. Rollback：功能开关可暂时关闭 trial soft（仅 VIP/付费）；槽位删除难回滚，宜确认后发。

## Open Questions

- （已关闭）试用时长 24h；claim 在成功后；方案 A 多次生成；其它方式 → `/features/unlock`；结果复合键；无广告；无存量付费。
- 实施时若 Admin 仍展示 prediction_unlock / ad，是否同期藏 UI：建议 **是**，列入 Go Admin 清理任务。
