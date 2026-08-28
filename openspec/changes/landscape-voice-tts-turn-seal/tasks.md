## 1. 串行管道与播放看门狗

- [x] 1.1 `VoiceChatWsClient`：`audio_chunk` / `audio_end` 改为串行 pipeline（single-flight 链），保证 end 取缓冲前已 append 入队 chunk
- [x] 1.2 `_playPcm16Le`：按 PCM 时长 + slack 计算超时（含下限与硬上限，替换固定 2 分钟）；超时 stop player 并打 `tts play timeout seal`
- [x] 1.3 `_onAudioEnd`：非 discard 时，播完 / 超时 / 播放异常后 MUST `_emit(VoiceChatTurnEnded)` 携带已解析 `finish_talk`；discard 路径保持不发 TurnEnded

## 2. 校验与验收

- [x] 2.1 `openspec validate landscape-voice-tts-turn-seal --strict`
- [ ] 2.2 手工：横屏唤醒对话；关注偶发「声停字幕不消」是否在数秒～数十秒内清字幕并进入「请说话」或回唤醒；有 `finish_talk` 日志；barge-in 打断仍正常；无裸 print
