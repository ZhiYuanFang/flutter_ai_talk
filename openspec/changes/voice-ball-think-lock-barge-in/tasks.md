## 1. 思考常亮

- [x] 1.1 思考窗进入时以独立原因 `WakelockPlus.enable`，开播 / 失败收口 / deactivate / dispose 释放该原因
- [x] 1.2 与横屏沉浸投屏锁做引用计数：任一侧仍需要则保持 enable，避免互相 `disable`

## 2. 播中开口即打断（已撤回）

播放中占麦会停掉回复音频。下列任务改由 `tts-playback-no-interrupt` 撤销，收版不得再要求播中打断。

- [x] 2.1 撤回：不再在 TTS 开播后本地采集 PCM
- [x] 2.2 撤回：播中不得 `stopTts`
- [x] 2.3 撤回：播中点按不得走停播收口
- [x] 2.4 思考窗保持唤醒词打断

## 3. 回前台不重播

- [x] 3.1 撤回：仅 `stop()` 盖不住熄屏续播，改由 `voice-pause-release-playback` 在暂停时 release
- [x] 3.2 等待播完被打断时按 discard 收口，不补成功 `VoiceChatTurnEnded`

## 4. 验收对照

- [x] 4.1 对照本 change specs：思考常亮、思考窗仍唤醒词、resume 不重播；播中打断已撤回
- [x] 4.2 无 `app/android/**` 变更；未新增裸 `debugPrint`/`print`
