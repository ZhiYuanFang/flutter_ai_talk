## 1. Go G1（兄弟仓）

- [x] 1.1 在 `go_ai_talk/internal/controller/voice_ws.go`：`openStreamASR` 成功后重置首字等待锚点（`streamStartAt` 或独立 `asrWaitStartAt`），并确认 `wsInitialNoASRGap` 判定使用该锚点
- [x] 1.2 扫同文件内其它对 `streamStartAt` 的依赖，避免误伤自动 commit/日志；必要时改用独立变量
- [ ] 1.3 部署/本地跑 Go 后，用日志确认：久静再出声先「建连」且不在同一瞬间空 interrupt

## 2. Flutter：有效音与无声 5s

- [x] 2.1 `VoiceChatWsClient`：上送 PCM 时检测有效能量，暴露本轮 `hasEffectiveSpeech`（或回调）；`beginListen` 时复位
- [x] 2.2 `LandscapeVoiceController`：`beginListen` 成功后启动 5s Timer；有效音取消；超时走 `_exitWithWoXianTuiXia`（single-flight）
- [x] 2.3 日志：`[LandscapeVoice]` 记录 idle arm / cancel / fire

## 3. Flutter：asr_no_result 续听与播报修复

- [x] 3.1 已有有效音时的 `asr_no_result`：续听/`beginListen`，不走「我先退下了」主路径
- [x] 3.2 无有效音时：交给 5s 无声终局（可收窄/替换旧 2.8s grace 逻辑，避免双终局打架）
- [x] 3.3 修复 `playAssetWav` 的 `onTimeout` 类型，保证退下音可完整等待

## 4. Flutter：弹幕跟播完清

- [x] 4.1 去掉「字幕静止 3s 清空」；播完本地音 / TTS（`TurnEnded`）后 `_clearSubtitle`
- [x] 4.2 无播音结束路径同样清字幕；日志 `subtitle clear`

## 5. 验收

- [ ] 5.1 真机：安静 ≥5s → 退下音；开口后不秒退可说话；中间空片段不整轮退下
- [ ] 5.2 确认 Go 与 Flutter 均已更新后再验收「久静再出声」
- [ ] 5.3 真机：答语弹幕在 TTS 播放期间可见，播完消失
