## 1. 停 TTS 与武装窗口

- [x] 1.1 `VoiceChatWsClient` 提供 `stopTts()`（停播放、清 PCM、丢弃至本轮 end 的迟到 chunk）
- [x] 1.2 `interrupt_commit` / 进入思考后：停上行麦 → 短延迟 → resume KWS（`_armBargeInWake`）；上行「请说话」阶段不开 barge-in

## 2. 打断与重开

- [x] 2.1 对话段内唤醒命中走 `_onBargeInWake`：停 TTS → `endSession` →「我在」→ `beginListen`；「我在」/交接期忙锁防自唤醒
- [x] 2.2 `finish_talk=false` 续听前再 pause KWS；下次 commit 再武装；`_finishTurn` 与 barge-in 不双抢

## 3. 验收

- [ ] 3.1 真机：思考中喊「你好，胖宝」→ 停回合并重新「我在」+可说话
- [ ] 3.2 真机：TTS 中喊唤醒词 → 立即停播并重开听；「我在」不自唤醒死循环
