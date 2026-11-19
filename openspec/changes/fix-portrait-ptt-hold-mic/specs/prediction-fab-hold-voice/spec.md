## ADDED Requirements

### Requirement: Portrait PTT hold MUST keep mic uplink despite server early commit frames

While a portrait go-record PTT hold is active (`_holdActive` / equivalent), the client MUST keep the microphone PCM uplink running even if the server sends `interrupt_commit` or an early `asr_no_result`. The client MUST NOT treat those frames as permission to stop the mic or end the user utterance for business purposes. Finger-up inside the keep zone (or explicit cancel) remains the sole business commit / cancel. 竖屏 PTT 按住期间即使收到服务端抢先 `interrupt_commit` / 早到 `asr_no_result`，客户端 MUST 保持开麦上行；MUST NOT 据此停麦或结束本轮用户话轮业务；松手（或取消）仍为唯一业务 commit/取消。

#### Scenario: interrupt_commit during hold does not stop mic

- **WHEN** 用户按住「去记录」PTT 且上行已开听
- **AND** 服务端下发 `interrupt_commit`
- **THEN** 客户端 MUST 继续 PCM 上送（MUST NOT `_stopMicOnly` 因该帧）
- **AND** MUST NOT 进入横屏式思考/ barge-in 收口
- **AND** 松手 keep 区内仍 MUST 发送业务 `commit`

#### Scenario: early asr_no_result during hold does not stop mic

- **WHEN** 用户按住 PTT 且尚未松手
- **AND** 服务端下发 `asr_no_result`
- **THEN** 客户端 MUST NOT 因该帧停麦
- **AND** MUST NOT 在按住期间用「没听清」替换「请说话…」作为成功聆听伪装的替代误导（可打日志；松手后若仍无有效结果再提示）

#### Scenario: Listening UI matches real mic state

- **WHEN** 按住期间麦克风实际上行已停止（异常路径）
- **THEN** UI MUST NOT 继续展示等同于正在聆听的「请说话…」而不作区分
- **AND** MUST 通过字幕或 pill 文案反映失败/需重试，或自动恢复上行
