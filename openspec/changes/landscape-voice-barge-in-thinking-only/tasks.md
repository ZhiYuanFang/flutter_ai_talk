## 1. 开播前 disarm 与播中门闩

- [x] 1.1 `VoiceChatWsClient`：增加 `onBeforeTtsPlay`（或等价）；`_onAudioEnd` 在 `_playPcm16Le` 前 await 回调；暴露 `isTtsPlaying`（或 provider 本地标志）
- [x] 1.2 `LandscapeVoiceController`：订阅/设置回调 → pause KWS + `_bargeInArmed=false`，Debug `bargeIn disarm reason=tts_start`；TurnEnded 时清「播中」标志
- [x] 1.3 `_onWakeDetection` / barge-in：播中 MUST 忽略；`onListenChipTap` 播中 MUST NOT `stopTts` 打断

## 2. 校验与验收

- [x] 2.1 `openspec validate landscape-voice-barge-in-thinking-only --strict`
- [ ] 2.2 手工：思考中喊唤醒词可打断；TTS 播放中开麦不应 pause 播（完整听完）；播中喊唤醒词不打断；`finish_talk=false` 仍续听；无裸 print
