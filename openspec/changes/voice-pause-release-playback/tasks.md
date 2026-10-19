## 1. 对齐未归档变更

- [x] 1.1 从 `voice-ball-think-lock-barge-in` 去掉较弱的 pause 停播规格，避免与本变更同题 ADDED 冲突
- [x] 1.2 同步该变更的 proposal / design：界面暂停释放音频改由本变更约束

## 2. 暂停即释放

- [x] 2.1 `inactive` / `hidden` / `paused` 时 stop 并 release 当前播放，丢弃缓冲
- [x] 2.2 `resumed` 不再播放该句，并再 stop/release 一次，挡住插件续播
- [x] 2.3 未播完话轮仍按 discard 收口，不补成功 `VoiceChatTurnEnded`

## 3. 验收

- [x] 3.1 对照本变更规格：熄屏或暂停释放、亮屏不补播
- [x] 3.2 无 `app/android/**` 变更；未新增裸 `debugPrint` / `print`
