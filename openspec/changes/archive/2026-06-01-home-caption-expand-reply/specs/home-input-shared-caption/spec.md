## MODIFIED Requirements

### Requirement: 统一字幕框与覆盖规则

The home input area SHALL use a single fixed-height caption slot for partial transcription and server reply, with server reply taking precedence; long server replies MUST remain preview-truncated in the slot but MAY be expanded via a separate interaction defined in `home-caption-expand-reply`. 主页主输入区必须使用**单一、固定高度**的字幕框展示转写与服务端回复，且同一时刻只显示一种文案（服务端回复覆盖转写）；预览仍限制为固定高度与最多 3 行省略；**服务端长回复**须支持通过「点击 → 底部抽屉」查看全文（详见 `home-caption-expand-reply`），且该能力**不适用于**转写预览。

#### Scenario: 回复覆盖转写预览

- **WHEN** 松手或提交后 `sendCommand` 返回非空 `reply`
- **THEN** 字幕框必须显示服务端回复并停止显示转写 partial

#### Scenario: 新一轮按住清空回复预览

- **WHEN** 用户开始新一轮按住说话
- **THEN** 字幕框必须清空上一轮服务端回复并重新显示转写或「聆听中…」

#### Scenario: 长回复预览仍截断

- **WHEN** 服务端回复长度超过字幕框 3 行容量
- **THEN** 字幕框预览必须使用省略号截断，完整内容通过底部抽屉展开获取
