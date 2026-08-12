## 1. VoiceChatWsClient 轮次契约

- [x] 1.1 解析 `answer` / `audio_end` 的 `finish_talk`，在 `VoiceChatTurnEnded`（或等价事件）上暴露；缺省按结束本段；Debug 记录取值来源
- [x] 1.2 实现 `restartAudioRound()`（`end`→`start`）与可复用的 `endSession()`/`sendEnd()`；single-flight；成功后更新 `_sessionStarted`
- [x] 1.3 `beginListen`（含 soft rearm）在需清 `waitEndAfterCommit` 时内部先 `restartAudioRound`，禁止仅凭 `_sessionStarted` 跳过
- [x] 1.4 `exit` 与客户端主动结束本段路径：停麦后连接仍开时 MUST `end`，再交还编排层

## 2. 横屏多轮编排

- [x] 2.1 `LandscapeVoiceController`：`TurnEnded(ok)` 按 `finishTalk` 分支——`false` → 续听「请说话…」并重置有效音 + 重武装 5s idle；`true`/缺省/`exit` → `end` 后 `_finishTurn` 回唤醒
- [x] 2.2 `_exitWithWoXianTuiXia` / 统一结束本段路径：在 `ensureMicStopped` 之后、回唤醒之前 MUST 调用 `endSession()`（或等价发 `end`）；Debug 记 `idle_exit end`
- [x] 2.3 `beginListen` 成功后收窄/清除 `_turnBusy`，避免整轮锁死芯片
- [x] 2.4 `onListenChipTap`：在「请说话…」假死时可强制复位（`end`/停麦/清忙）并重新开听或回唤醒，禁止无日志直接 return

## 3. 文档与验收

- [x] 3.1 更新 `app/README.md` 语音 chat WS 说明：意图层 `finish_talk`/`exit` + 传输层 `end`/`start` + idle 退下 MUST `end`
- [ ] 3.2 真机验收：续聊两轮；续听后 5s 无声退下且可见 `end`；`finish_talk=true`/`exit` 回唤醒亦见 `end`；卡死后点话筒可恢复
- [x] 3.3 确认未引入裸 `debugPrint`/`print`；未新建 `**/test/**`
