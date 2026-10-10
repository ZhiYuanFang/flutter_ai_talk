## 1. 接线 ASR

- [x] 1.1 在成长轨迹屏持有/复用 `HomeSpeechRecognizer`（`createHomeSpeechRecognizer`）；开听前 ensure 全局 `VoiceAsrWsClient` 已连接
- [x] 1.2 提交答案、新 question、离开 asking 时 cancel/end 进行中的语音会话

## 2. 追问 UI

- [x] 2.1 `free_text`：TextField 旁增加按住说话控件（交互对齐伴侣页）
- [x] 2.2 choice「手动输入」展开后同样展示按住说话；双按钮态不展示
- [x] 2.3 partial/final 写入答题控制器；松手不自动 submit；失败 Toast 既有失败文案

## 3. 验收

- [x] 3.1 对照 `growth-trajectory-voice-input` 与 `growth-trajectory-predict` MODIFIED 情景走查
- [x] 3.2 确认未新建第二条 ASR、未接入 `/voice/chat/ws`
