## 1. VoiceChatWsClient 门闩

- [x] 1.1 增加 hold 上行保护门闩（API 自定），默认关闭
- [x] 1.2 `interrupt_commit`：门闩开启时 emit 事件但 MUST NOT `_stopMicOnly`；关闭时保持现行为
- [x] 1.3 `asr_no_result`：门闩开启时 emit 事件但 MUST NOT `_stopMicOnly`；关闭时保持现行为
- [x] 1.4 `endSession` / `dispose` / 显式停麦路径不受门闩阻碍（客户端主动停麦仍可用）

## 2. LandscapeVoiceController 编排

- [x] 2.1 `startHold` 成功开听前/时置门闩 true；`endHold` / `deactivate` / `_tearDown` 清 false
- [x] 2.2 按住期间收到 interrupt / asr_no_result：继续忽略业务收口；补 `[LandscapeVoice]` 日志
- [x] 2.3 按住期间若发现 `!isListening`：更新字幕/状态，禁止继续伪装「请说话…」；可尝试一次续听或提示重按
- [x] 2.4 startHold 早退路径（inactive / micDenied 等）补日志与失败字幕

## 3. FAB / 验收

- [x] 3.1 pill 聆听文案与 `chatListening` / 真实开麦一致（失败不装「请说话…」）
- [x] 3.2 `dart analyze` 相关改动文件无 issue
- [ ] 3.3 真机：竖屏长按说话可见实时 ASR；松手有正常答复；横屏 interrupt 收口仍正常
