## ADDED Requirements

### Requirement: 思考窗 MUST 保持屏幕常亮

While the prediction voice session (portrait voice ball or landscape listen chip) is in the thinking window — user utterance committed and reply TTS has not started — the client MUST keep the screen awake via `WakelockPlus` (or equivalent). When thinking ends because reply TTS playback starts, the turn fails, or the session deactivates, the client MUST release this thinking wake reason. The landscape immersive cast wake lock MUST remain independent: releasing the thinking reason MUST NOT disable the screen wake while cast immersion still requires it, and ending cast MUST NOT drop the wake lock while thinking still requires it.

预测语音思考窗（竖屏球或横屏芯片，已提交且回复 TTS 未开播）客户端 MUST 保持屏幕常亮。开播、本轮失败或会话停用 MUST 释放该思考原因。横屏沉浸投屏常亮 MUST 独立：释放思考原因 MUST NOT 关掉仍需要的投屏锁，结束投屏 MUST NOT 关掉仍在思考的锁。

#### Scenario: 思考中不熄屏

- **WHEN** 预测语音进入思考窗且系统空闲超时已到
- **THEN** 客户端 MUST 仍保持屏幕点亮

#### Scenario: 开播后释放思考锁

- **WHEN** 回复 TTS 开始播放
- **THEN** 客户端 MUST 释放思考常亮原因
- **AND** 若无沉浸投屏仍要求常亮，屏幕 MAY 随后按系统策略熄灭
