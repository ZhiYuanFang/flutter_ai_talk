## 1. 竖屏 PTT 去掉并行 ding

- [x] 1.1 `startHold`：`beginListen` 成功后移除（或不调用）`playAssetWav(kLandscapeDingAsset)`
- [x] 1.2 确认横屏 `_onWake` / barge-in 的 ding 路径未改
- [ ] 1.3 热重载/重启后竖屏长按：日志出现 `pcm chunkAvgAbs` / `effectiveSpeech`；松手有 ASR/答复

## 2. 横屏 KWS 恢复

- [x] 2.1 核对 `finishTurn` / chip 收尾必调用 `_restoreWakeListening`；竖屏→横屏 `activate` 必 `_attachWakeListening`
- [x] 2.2 `resume` 失败路径：fallback `start`、失败 status + `[LandscapeVoice]`/`[LandscapeKws]` 日志
- [x] 2.3 必要时在 restore 前保证 chat 麦已停尽（间隙）；避免双录音机争用
- [ ] 2.4 真机：chip 一轮后说「胖宝」可唤醒；失败时点 chip 仍可用

## 3. 校验

- [x] 3.1 `dart analyze` 相关文件无 issue
- [x] 3.2 （可选）hold 无有效音短窗弱提示；非阻塞 — 跳过，先验证 PCM
