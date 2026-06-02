## MODIFIED Requirements

### Requirement: 输入 dock 视觉与数据流隔离

The input mode dock SHALL align visually with the bottom panel tokens while preserving voice and button mode switching on mobile (and Web text/voice policy unchanged) and WS/history flows. **输入模式 dock** MUST 与底部 panel 视觉统一（surface/shadow）；**不得**改动语音录制、按钮 add 与历史 **WebSocket** 数据流；移动端模式切换为 **voice ↔ buttons** 轮转。

#### Scenario: 移动端两模式切换

- **WHEN** 用户在 Android/iOS 通过 dock 在语音与按钮间切换
- **THEN** 必须仍展示对应主输入 UI（语音球/事件网格），仅容器样式随 tokens 更新

#### Scenario: 历史 WS 推送新行

- **WHEN** 按钮或语音成功落库后 WS 推送新历史
- **THEN** 列表更新行为必须与升级前一致，不得依赖主题变更
