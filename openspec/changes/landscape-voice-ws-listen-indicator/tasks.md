## 1. Debug 白名单

- [x] 1.1 新增 `AppDebugLog.landscapeVoice`（tag `[LandscapeVoice]`）
- [x] 1.2 三联更新：`logcat_api_http.ps1`、`app/README.md` Debug 表

## 2. 状态与 chip 指示

- [x] 2.1 `LandscapeVoiceUiState` 增加 `chatConnected` / `chatListening`；订阅 `readyStream` 并在开听/停麦/结束轮次同步
- [x] 2.2 `_LandscapeVoiceListenChip`：话筒旁红/绿点；仅 `chatConnected && chatListening` 时话筒高亮；已连待唤醒绿点亮不高亮

## 3. 唤醒开听防挂死

- [x] 3.1 `_onWake` 分阶段文案；`pause` / `startStream`（及短延迟）超时；失败短因 + 清 `_turnBusy` + resume KWS；`!_active` 提前返回也清忙锁
- [x] 3.2 `beginListen`/`ensureSessionStarted` 路径打 `[LandscapeVoice]` 步骤日志

## 4. 验收

- [ ] 4.1 真机：待唤醒绿点；断网/未连红点；唤醒后应到「请说话…」且绿+高亮，不得无限「我在听…」
