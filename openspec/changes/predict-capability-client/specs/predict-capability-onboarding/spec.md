## ADDED Requirements

### Requirement: Client SHALL remind once per baby when local affinity becomes ready

When the silent rail first has at least one non-appointment root whose affinity path can produce a nextAt, and predict display entitlement is inactive, and the current `deviceNo` has not been marked reminded, the client SHALL show a glass-morphism dialog. The dialog copy MUST state that 智能预测基础版已生效 and that the app will predict the next occurrence from the baby’s feeding frequency (MUST NOT say「本地预测算法已生效」). The dialog MUST show a large circular green background with a white checkmark, and bottom actions「取消」and「立即体验」. As soon as the dialog is shown, the client MUST persist a reminded flag scoped to the current baby `deviceNo` so the dialog MUST NOT appear again for that baby. Binding an existing baby that already meets the affinity gate (skipping interval cold onboarding) MUST still count as a first-remind opportunity when the flag is unset.

任一事件亲和可产出且未 entitle、本宝宝未提醒时 MUST 弹窗；一展示 MUST 写宝宝维已提醒；文案 MUST 为商业基础版口径；新绑固有宝宝亦算首次。

#### Scenario: 弹窗即标记

- **WHEN** 条件满足并成功展示该玻璃弹窗
- **THEN** 本地 MUST 已写入该 deviceNo 的已提醒标记
- **AND** 用户点「取消」关闭后，再次进入预测页 MUST NOT 再弹

#### Scenario: 已 entitle 不弹

- **WHEN** 用户已有 basic 或 pro 有效权益或 isVip=true
- **THEN** MUST NOT 展示该首次提醒弹窗

#### Scenario: 换宝宝独立

- **WHEN** deviceNo 从 A 切换到从未提醒过的 B，且 B 上亲和已就绪且未 entitle
- **THEN** MUST 允许对 B 再展示一次提醒弹窗

### Requirement: 立即体验 SHALL call trial start for basic without opening unlock hub

Tapping「立即体验」MUST call `POST /cash/app/api/feature/trial/start` with `featureId=predict_capability_basic` in the current logged-in bound session, and MUST NOT navigate to the feature unlock hub solely to claim trial. On success, the client MUST refresh feature catalog, then show a glass success dialog stating 智能预测基础版体验成功 and that it will expire in X days (X from entitlement expiresAt or server trial duration of 7 days), with smaller secondary copy that after expiry the surface falls back to 固定间隔节奏. On failure, the client MUST show an error toast or dialog and MUST NOT pretend entitlement was granted.

立即体验 MUST 直接点试用 basic；成功后 MUST 成功弹窗含到期天数与回退固定间隔小字。

#### Scenario: 试用成功

- **WHEN** 用户点「立即体验」且服务端 trial/start 成功
- **THEN** 客户端 MUST 刷新 catalog
- **AND** MUST 展示成功弹窗含剩余/授予天数与回退固定间隔说明
- **AND** 随后展示轨 MUST 按已 entitle 切换为亲和

#### Scenario: 试用已领取

- **WHEN** 服务端返回试用已领取或等价业务错误
- **THEN** 客户端 MUST 提示失败且 MUST NOT 将展示轨误切为已开通

### Requirement: Reminded flag SHALL be wiped with baby-scoped local state

Account wipe or clearing the bound device identity MUST clear the per-deviceNo reminded flag together with other baby-scoped prediction local state.

卸号/清宝宝本地态 MUST 清除已提醒标记。

#### Scenario: wipe 后可再提醒

- **WHEN** 用户执行账号本地擦除或解除绑定清除 deviceNo 后再绑定同一或另一宝宝且条件再次满足
- **THEN** 若新会话下该 deviceNo 无已提醒标记，MUST 允许再次提醒
