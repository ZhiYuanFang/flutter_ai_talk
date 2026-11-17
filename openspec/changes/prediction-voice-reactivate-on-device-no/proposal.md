## Why

预测语音在表面可见时调用 `activate`，若此时 `deviceNoNotifier` 仍为初始 `AsyncValue.data(null)`（prefs 尚未 refresh），会误判为未绑定并展示「绑定宝宝后可语音完成喂养记录」，且 `_active` 保持 false。随后 `deviceNo` 就绪时，lifecycle binder 不因 dn 变化重 sync，会话卡住；点球也不会补激活。已绑定用户冷启常见此竞态，需在 dn 从空→有时自动补 `activate`。

## What Changes

- **listen `deviceNo`**：预测语音会话在 surface want 期间，当 `deviceNo` 从空/缺失变为非空时，MUST 再次尝试 `activate`（含 soft-check 麦权路径，与 `defer-mic-until-voice-ball` 一致）。
- **避免假「未绑定」终态**：不得因一次空读永久停在绑定文案；dn 就绪后 MUST 进入已授权唤醒或未授权 `micDenied` 点按路径。
- **可选加固**：监听入口在会话未 `_active` 且 dn 已可用时，点按 MUST 可触发补激活（兜底）。
- **非 BREAKING**：无后端/API 变更。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `prediction-landscape-voice`：surface want 下 `deviceNo` 晚到时 MUST 补激活；不得把冷启空读当成永久未绑定。
- `prediction-portrait-voice-dock`：竖屏表面同样适用（共用 controller / lifecycle）。

## Impact

- **Flutter**：`landscape_voice_provider.dart`（listen / 补 activate）、必要时 `landscape_voice_lifecycle_binder.dart`；与 `deviceNoNotifierProvider`、既有 soft-check 麦权路径交互。
- **依赖**：`defer-mic-until-voice-ball` 的 soft-check / 半激活语义应保持；本变更只修 dn 竞态。
- **风险**：重复 activate 须继续靠 `_active` / in-flight 单飞，避免双开 KWS。
