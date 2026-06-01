## ADDED Requirements

### Requirement: 主输入区统一字幕框

The system SHALL provide a single fixed-height caption area above the primary voice orb or text submit control on the home screen, and MUST NOT render separate stacked caption blocks for transcript preview and server reply below the control. 系统必须在主页主输入控件（语音球或文字提交区）**上方**提供**唯一**、**固定高度**的字幕展示区域；实时转写预览与服务端对话回复**不得**在主控件下方再各占一行叠放。

#### Scenario: 语音模式仅一个字幕框

- **WHEN** 用户处于语音输入且正在按住说话或已展示转写/回复
- **THEN** 转写与服务端回复必须出现在同一字幕框内，且该区域高度不得随回复变长而撑开底部输入区

#### Scenario: 文字模式复用同一字幕框

- **WHEN** 用户处于文字输入并提交指令后收到服务端回复
- **THEN** 回复必须显示在与语音模式相同的字幕框组件中，且不得再在输入框下方单独增加一行回复文案

### Requirement: 转写与回复的覆盖顺序

The system SHALL display at most one primary caption string using priority: server reply over transcript preview. 系统在同一时刻必须只显示一条主字幕；**服务端回复**优先于**转写预览**；当回复非空时必须覆盖转写内容。

#### Scenario: 回复覆盖转写

- **WHEN** 用户松开语音控件后字幕框仍显示转写，且 `sendCommand` 返回非空回复
- **THEN** 字幕框必须改为显示该回复，且不得同时在框外保留原转写行

#### Scenario: 按住期间显示转写

- **WHEN** 识别引擎向 UI 推送非空 partial 文本且尚无服务端回复
- **THEN** 字幕框必须显示该转写并随 partial 更新

### Requirement: 松手后保留转写直至覆盖

The system MUST keep the last non-empty transcript visible in the caption area after the user releases the voice control until a server reply overwrites it or a new utterance starts. 用户**松手**后系统**不得**立即清空字幕框中的转写；必须保留至服务端回复写入字幕框，或用户开始新一轮按住说话为止。

#### Scenario: 松手不清空转写

- **WHEN** 用户松开语音控件且已获得非空 final 或 partial 文本，但服务端回复尚未返回
- **THEN** 字幕框必须继续显示该转写（或最终转写），直至回复到达或新一轮采集开始

#### Scenario: 新一轮按住清空

- **WHEN** 用户再次按下语音控件开始新一轮采集
- **THEN** 系统必须清空上一轮服务端回复与转写缓存，字幕框随新 partial 更新

#### Scenario: 取消采集

- **WHEN** 用户取消当前语音采集（pointer cancel 或等价取消）
- **THEN** 系统必须清空进行中的转写展示（字幕框可不显示转写或恢复仅显示既有回复，若产品无回复则为空）
