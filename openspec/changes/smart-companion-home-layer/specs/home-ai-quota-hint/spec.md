## REMOVED Requirements

### Requirement: Voice mode SHALL show AI chat quota below voice orb with glass styling

**Reason**: 产品决定客户端先行取消 voiceAi / clinicAi / polish 额度展示与限制；喂养语音球下方额度胶囊不再符合产品语义。

**Migration**: 移除 `HomeScreen` 上 `AiQuotaRemainingHint(feature: voiceAi)`（及等价展示）；语音模式布局不再为额度条预留纵向空间。额度 HTTP 拉取可保留但不驱动 UI；后端取消限额另 change。

## ADDED Requirements

### Requirement: Feeding voice mode MUST NOT show AI quota remaining UI

On the feeding home screen, when `HomeInputChannel.voice` is active, the client MUST NOT display monthly AI dialogue remaining quota (`voiceAi`) or degraded-quota copy near the voice orb. 喂养语音模式下客户端 **不得** 在语音球附近展示 AI 对话额度剩余或降速文案。

#### Scenario: 语音模式无额度胶囊

- **WHEN** 用户处于喂养主页语音输入模式
- **THEN** UI MUST NOT 展示「本月 AI 对话剩余 N 次」或「额度已用完，已降速」类提示

### Requirement: Feeding AI paths MUST NOT present 40302 as quota UX

For feeding home AI dialogue (`sendCommand` / voice paths), the client MUST NOT present business code 40302 as a monthly quota-exhausted glass dialog. Login code 40301 MAY remain. 喂养 AI 对话路径对 40302 **不得** 展示额度用尽 Glass 弹框；40301 MAY 保留。

#### Scenario: 40302 不弹额度框

- **WHEN** 喂养 AI 接口返回业务码 40302
- **THEN** 客户端 MUST NOT 弹出「本月额度已用完」类弹框
