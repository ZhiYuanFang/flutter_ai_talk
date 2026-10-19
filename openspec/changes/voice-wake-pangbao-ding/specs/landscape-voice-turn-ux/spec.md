## MODIFIED Requirements

### Requirement: 横屏语音字幕弹幕 MUST 随内容布局并自动消失

Landscape voice subtitle toast MUST size to its text (with a max width within screen insets) and MUST wrap long text onto multiple lines. Thinking and answer subtitles MUST auto-clear when that text has not changed for 3 seconds. Status subtitles for wake acknowledgement and in-turn guidance （「我在」「请说话」「连接中」及等价连接文案） MUST stay visible until replaced by a newer subtitle or until the turn returns to wake-waiting, and MUST NOT auto-clear only because 3 seconds passed. 横屏语音字幕弹幕 MUST 按文本收缩宽度（在屏幕边距内设上限）、超长 MUST 换行。思考与回答字幕在文本 **3 秒无变更** 时 MUST 自动清空。唤醒确认与回合引导状态字幕（「我在」「请说话」「连接中」及等价连接文案）MUST 保留到被更新的字幕替换，或直到回到待唤醒，MUST NOT 仅因满 3 秒而清空。

#### Scenario: 短文本收窄

- **WHEN** 字幕为短句（如「我在」）
- **THEN** 弹幕容器 MUST NOT 无必要拉满整屏宽度（应随内容，受 maxWidth 约束）

#### Scenario: 长文本换行

- **WHEN** 字幕长度超过可用最大宽度
- **THEN** 文本 MUST 自动换行完整展示

#### Scenario: 静默 3 秒消失

- **WHEN** 思考或回答字幕展示后连续 3 秒没有新的字幕文本变更
- **THEN** 该字幕 MUST 自动消失（清空）

#### Scenario: 状态字幕不因静默消失

- **WHEN** 字幕正在展示「我在」「请说话」或「连接中」，且该状态仍是当前回合状态
- **THEN** 客户端 MUST NOT 因 3 秒无新文本而清空它

#### Scenario: 新文本重置计时

- **WHEN** 思考或回答字幕在倒计时内被更新为新文本
- **THEN** 自动消失计时 MUST 重新从 3 秒起算
