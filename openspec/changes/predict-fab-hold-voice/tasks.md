## 1. Chat WS modality 与 text 收口

- [x] 1.1 `VoiceChatWsClient.ensureSessionStarted`（及 round restart）支持按会话传入 `outputModality`，写入 `start` JSON
- [x] 1.2 text 模式下以 `answer`（含 `finish_talk`）seal `TurnEnded`，不得死等 `audio_end`；audio 模式保持既有 TTS 播完收口
- [x] 1.3 确认 `commitUtterance` 可被 PTT 松手路径调用；补充必要 `AppDebugLog.landscapeVoice`（或既有 tag）日志

## 2. 无唤醒 hold API 与方向切换

- [x] 2.1 从 `LandscapeVoiceController` 抽出（或并列实现）`startHold` / `endHold(cancel:)`：无 KWS、可 ding、`beginListen`、松手 commit / 取消停麦
- [x] 2.2 holding 期间忽略服务端抢先 `interrupt_commit` 的业务收口；松手为唯一业务 commit
- [x] 2.3 竖屏表面可见预连 chat WS（不开麦、不启 KWS）；离开表面 teardown
- [x] 2.4 竖↔横旋转：取消 hold、end 会话窗，按方向重绑（竖屏 text 预连 / 横屏 audio+KWS）；下次 `start` 带正确 modality
- [x] 2.5 横屏 `start` 明确 audio；回归唤醒、TTS、续听不被 text seal 破坏

## 3. 「去记录」FAB 手势与 UI

- [x] 3.1 pill 增加副文案「· 长按语音记录」；短按仍切喂养并上报；长按进入 PTT（阈值后触感可选）
- [x] 3.2 滑出取消：keep 区 = pill bounds inflate 默认 32dp（24–40 可调常量）；区外武装取消，松手 cancel
- [x] 3.3 竖屏 PTT 字幕复用 `LandscapeVoiceSubtitleToast`（不依赖已删球挂载）
- [x] 3.4 麦权：长按触发用途框流程（对齐横屏点 chip），表面可见不弹框
- [x] 3.5 新增 FAB 心跳 request provider；pill 消费后 Scale 心跳恰 3 次，不自动开麦

## 4. 删除竖屏语音球与基础版墙改导

- [x] 4.1 移除 `kPredictionPortraitVoiceEnabled` 及 `UcgHomeShell` 竖屏 binder / `PredictionVoiceEdgeDock` / engage listen
- [x] 4.2 删除或停用 `predictionVoiceEngageRequestProvider`；清理球专用 occupancy/store 引用（若仅球使用）
- [x] 4.3 基础版条目文案改为长按语音记录导向；tap → 关墙 + FAB 心跳 request（不再 `showEngaged`）
- [x] 4.4 更新 `_VoiceBallDemo`（或更名）示意，避免仍承诺竖屏唤醒球
- [x] 4.5 更新 `app/README.md` 中预测竖屏语音 / Debug 相关描述（若有球入口说明）

## 5. 验收

- [x] 5.1 竖屏：短按去喂养；长按 ding→说话→松手出字幕答复；滑出取消无 commit；无 TTS、无退场音
- [x] 5.2 横屏：唤醒/点麦仍播 TTS；与竖屏旋转后 modality 正确切换
- [x] 5.3 基础版墙点该条目：关墙后「去记录」心跳 3 次且不开麦
- [x] 5.4 确认竖屏无 EdgeDock 语音球残留入口
