## 1. 持久化

- [x] 1.1 新增 `app/lib/config/ai_chat_data_consent_store.dart`：`load()` / `saveAccepted()`，SharedPreferences 键 `ai_chat_data_consent_v1`
- [x] 1.2 确认登出流程不调用 clear（与 design 一致，设备级偏好）

## 2. 首页门控

- [x] 2.1 在 `HomeScreen` 实现 `_ensureAiChatDataConsent({int? voiceHoldSeq})`：已同意则短路；否则 `showGlassConfirmDialog`（标题/正文/「取消」「同意并继续」）
- [x] 2.2 在 `_onVoicePointerDown` 中于 `_ensureRemoteGate` 之后插入同意门；取消则 return；同意后若 `!_isVoiceHoldCurrent(seq)` 则 return
- [x] 2.3 在 `_onTextSubmit` 中于 `_ensureHistoryWsForSend` 之后、`sendCommand` 之前插入同意门；取消则 return 且保留输入框内容

## 3. 规格对齐与验证

- [x] 3.1 确认 `_onVoiceEnd` 不重复门控（按下时已拦截）
- [x] 3.2 确认设置中心无新增撤回相关 UI
- [x] 3.3 手工验证：未同意时每次按住/每次提交均弹窗；同意后均不再弹；取消不开录/不发送
- [x] 3.4 手工验证：弹窗无勾选框、无隐私政策链接；切换语音识别引擎后文案不变
