## 1. 对齐未归档变更规格

- [x] 1.1 从 `voice-ball-think-lock-barge-in` 的 barge-in delta 去掉「废止播放窗禁止打断」以及「开口打断 / 播中点按停 TTS」；保留思考常亮
- [x] 1.2 同步该变更的 proposal / design，使收版不会再写回播中打断

## 2. 播放窗不再占麦、不再停播

- [x] 2.1 删除回复 TTS 播中的本地能量检测与 `onTtsSpeechBarge`，开播后不再 `startStream`
- [x] 2.2 播放中唤醒词、横屏芯片、竖屏语音球点按不得 `stopTts`；思考窗唤醒词打断保持
- [x] 2.3 思考常亮、沉浸锁计数、进后台停播且 resume 不重播保持不动

## 3. 验收

- [x] 3.1 对照本变更规格：播中不占麦、开口与点按不停播、思考窗仍可唤醒词打断
- [x] 3.2 无 `app/android/**` 变更；未新增裸 `debugPrint` / `print`
