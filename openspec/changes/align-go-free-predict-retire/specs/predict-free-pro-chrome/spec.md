## ADDED Requirements

### Requirement: Free tier SHALL be a client-only label without featureId

The client SHALL present「免费版」as a pure client chrome label with no cash catalog `featureId` and MUST NOT invent a local `predict_capability_basic` (or equivalent) commercial row. Free-tier affinity prediction and affinity progress MUST remain available without payment, trial, or VIP. Pro commercial state MUST come only from catalog item `predict_capability_pro` (and Go Pro eligibility / trial APIs when used).

「免费版」MUST 为无 featureId 的客户端标签；MUST NOT 伪造 basic 商业项；免费亲和预测/进度 MUST 无需付费；Pro MUST 仅来自 `predict_capability_pro`。

#### Scenario: 无 basic catalog 仍显示免费版

- **WHEN** feature catalog 不含 `predict_capability_basic`
- **THEN** 预测页档位后缀仍 MAY 显示「免费版」
- **AND** MUST NOT 因缺少 basic 项而隐藏亲和预测或进度

### Requirement: Predict tier chrome SHALL expose only Free and Pro

When bound smart-prediction「接下来3小时」shows a tier suffix (or the full-screen tier wall), the client MUST use exactly one of：`· 免费版` / `· Pro版`, choosing Pro when `predict_capability_pro` is time-valid unlocked, otherwise Free. The client MUST NOT show「间隔版」「基础版」or VIP-as-tier copy. Tapping the suffix MUST open a two-tier explanation surface (not a three-tier VIP wall). While catalog/Pro eligibility needed for the suffix is still loading, the client MAY show a non-final syncing placeholder that MUST NOT open the wall as if settled, and MUST NOT await VIP status for that decision.

3h 档位 MUST 仅为免费版/Pro版；MUST NOT 出现间隔/基础/VIP 档；开墙 MUST 为两档；同步占位 MUST NOT 依赖 VIP settle。

#### Scenario: Pro 优先

- **WHEN** `predict_capability_pro` 时间有效开通
- **THEN** 后缀 MUST 为「· Pro版」

#### Scenario: 非 Pro 为免费版

- **WHEN** Pro 未开通且 catalog/eligibility 已就绪
- **THEN** 后缀 MUST 为「· 免费版」
- **AND** MUST NOT 显示「· 间隔版」或「· 基础版」

### Requirement: Client SHALL load predict-pro eligibility separately from affinity progress

Before offering Pro unlock payment or trial CTAs that Go gates on eligibility, the client SHALL call `GET /cash/app/api/predict-pro/eligibility` under the logged-in bound session (deviceNo via gateway headers only), with single-flight and failure circuit-breaker on automatic refresh. Affinity progress UI MUST NOT require this eligibility response. Eligibility failure MUST NOT block free-tier prediction or progress rendering.

Pro 开通前置 MUST 拉 `predict-pro/eligibility`；亲和进度 MUST NOT 依赖该接口；eligibility 失败 MUST NOT 挡住免费预测/进度。

#### Scenario: 进度不挡在 eligibility

- **WHEN** predict-pro eligibility 请求失败或 loading
- **AND** 某卡无亲和 nextAt
- **THEN** 该卡仍 MUST 可展示亲和进度条与文案
